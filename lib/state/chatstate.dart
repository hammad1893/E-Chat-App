// state/chatstate.dart
import 'package:chat_app/model/chatmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatId(String user1, String user2) {
    List<String> users = [user1, user2];
    users.sort();
    return "${users[0]}_${users[1]}";
  }

  Stream<Map<String, dynamic>> getUserStatusStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  Future<void> updateUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<List<MessageModel>> getMessagesStream(
    String chatId,
    String currentUserId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                if (data['hiddenFor'] != null &&
                    (data['hiddenFor'] as List).contains(currentUserId)) {
                  return null; // hidden → filtered out
                }
                return MessageModel.fromMap(data, doc.id);
              })
              .whereType<MessageModel>() // removes nulls
              .toList();
        });
  }

  // FIXED: Enhanced method to check if current user is blocked by another user
  Future<bool> isBlockedByUser(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final otherUserDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      final blockedUsers = List<String>.from(
        otherUserDoc.data()?['blockedUsers'] ?? [],
      );
      return blockedUsers.contains(currentUser.uid);
    } catch (e) {
      print('Error checking if blocked by user: $e');
      return false;
    }
  }

  Future<bool> canSendMessage(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // Check if receiver has blocked current user (they blocked me)
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final receiverBlockedUsers = List<String>.from(
        receiverDoc.data()?['blockedUsers'] ?? [],
      );

      if (receiverBlockedUsers.contains(currentUser.uid)) {
        return false; // They blocked me - I cannot send
      }

      // Check if current user has blocked receiver (I blocked them)
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserBlockedUsers = List<String>.from(
        currentUserDoc.data()?['blockedUsers'] ?? [],
      );

      if (currentUserBlockedUsers.contains(receiverId)) {
        return false; // I blocked them - they cannot send to me
      }

      return true;
    } catch (e) {
      print('Error checking message permissions: $e');
      return false;
    }
  }

  // ✅ FIXED: Enhanced blocking logic
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? mediaUrl,
    String messageType = 'text',
    Map<String, dynamic>? contactInfo,
  }) async {
    if (text.trim().isEmpty && mediaUrl == null && contactInfo == null) return;

    final chatId = getChatId(senderId, receiverId);

    try {
      // ✅ Check if sender can send message (considering both sides blocking)
      final canSend = await canSendMessage(receiverId);
      if (!canSend) {
        throw 'Cannot send message. You may have been blocked or have blocked this user.';
      }

      // Build message
      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'mediaUrl': mediaUrl,
        'messageType': messageType,
        if (contactInfo != null) 'contactInfo': contactInfo,
        'delivered': true,
      };

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update chat document
      String lastMessageText = text.trim();
      if (lastMessageText.isEmpty) {
        switch (messageType) {
          case 'image':
            lastMessageText = '📷 Photo';
            break;
          case 'document':
            lastMessageText = '📄 Document';
            break;
          case 'audio':
            lastMessageText = '🎤 Voice message';
            break;
          case 'contact':
            lastMessageText = '👤 Contact';
            break;
          default:
            lastMessageText = 'Message';
        }
      }

      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {senderId: 0, receiverId: FieldValue.increment(1)},
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // ✅ Enhanced block user - proper Firestore handling
  Future<void> blockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // ✅ Use set with merge to ensure field exists
      await _firestore.collection('users').doc(currentUser.uid).set({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // final chatId = getChatId(currentUser.uid, blockedUserId);
      // await _firestore.collection('chats').doc(chatId).set({
      //   'lastMessage': '🚫 You blocked this contact',
      //   'lastMessageTime': FieldValue.serverTimestamp(),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // }, SetOptions(merge: true));
      final chatId = getChatId(currentUser.uid, blockedUserId);
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': '🚫 You blocked this contact',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {currentUser.uid: 0, blockedUserId: 0},
      }, SetOptions(merge: true));

      print('✅ Successfully blocked user: $blockedUserId');
      notifyListeners();
    } catch (e) {
      print('❌ Error blocking user: $e');
      rethrow;
    }
  }

  // ✅ Enhanced unblock user - proper Firestore handling
  Future<void> unblockUser(String unblockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // ✅ First check if user is actually in blocked list
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final blockedUsers = List<String>.from(
        userDoc.data()?['blockedUsers'] ?? [],
      );

      if (!blockedUsers.contains(unblockedUserId)) {
        print('⚠️ User $unblockedUserId is not in blocked list');
        return;
      }

      // ✅ Use set with merge and arrayRemove
      await _firestore.collection('users').doc(currentUser.uid).set({
        'blockedUsers': FieldValue.arrayRemove([unblockedUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final chatId = getChatId(currentUser.uid, unblockedUserId);
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': 'You unblocked this contact',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {currentUser.uid: 0, unblockedUserId: 0},
      }, SetOptions(merge: true));
      // final chatId = getChatId(currentUser.uid, unblockedUserId);
      // await _firestore.collection('chats').doc(chatId).set({
      //   'lastMessage': 'You unblocked this contact',
      //   'lastMessageTime': FieldValue.serverTimestamp(),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // }, SetOptions(merge: true));

      print('✅ Successfully unblocked user: $unblockedUserId');
      notifyListeners();
    } catch (e) {
      print('❌ Error unblocking user: $e');
      rethrow;
    }
  }

  Future<void> openDocument(String documentUrl, String fileName) async {
    try {
      final uri = Uri.parse(documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $documentUrl';
      }
    } catch (e) {
      print('Error opening document: $e');
      throw 'Failed to open document: $e';
    }
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      print(
        '🔵 Marking messages as read for chat: $chatId, user: $currentUserId',
      );

      // Get all unread messages for current user
      final messages =
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('receiverId', isEqualTo: currentUserId)
              .where('isRead', isEqualTo: false)
              .get();

      if (messages.docs.isEmpty) {
        print('✅ No unread messages found');
        // Still reset the count even if no messages found
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCounts.$currentUserId': 0,
        });
        notifyListeners();
        return;
      }

      print('📧 Found ${messages.docs.length} unread messages to mark as read');

      // Mark all messages as read
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // ✅ CRITICAL: Reset unread count to 0 in chat document
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$currentUserId': 0,
      });

      print('✅ Successfully marked messages as read and reset count');
      notifyListeners();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      // throw Exception('Failed to mark messages as read: $e');
    }
  }

  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold(0, (total, doc) {
            final unreadCounts = Map<String, dynamic>.from(
              doc.data()['unreadCounts'] ?? {},
            );
            return total + (unreadCounts[userId] ?? 0) as int;
          }),
        );
  }

  Stream<List<Map<String, dynamic>>> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'chatId': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      notifyListeners();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Future<void> unblockUser(String unblockedUserId) async {
  //   final currentUser = _auth.currentUser;
  //   if (currentUser == null) return;

  //   try {
  //     await _firestore.collection('users').doc(currentUser.uid).set({
  //       'blockedUsers': FieldValue.arrayRemove([unblockedUserId]),
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     final chatId = getChatId(currentUser.uid, unblockedUserId);
  //     await _firestore.collection('chats').doc(chatId).set({
  //       'lastMessage': 'Chat restored',
  //       'lastMessageTime': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     notifyListeners();
  //   } catch (e) {
  //     print('Error unblocking user: $e');
  //     rethrow;
  //   }
  // }

  Future<bool> isUserBlocked(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final blockedUsers = List<String>.from(
        userDoc.data()?['blockedUsers'] ?? [],
      );
      return blockedUsers.contains(otherUserId);
    } catch (e) {
      print('Error checking blocked status: $e');
      return false;
    }
  }

  Stream<List<String>> getBlockedUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore.collection('users').doc(currentUser.uid).snapshots().map((
      snapshot,
    ) {
      return List<String>.from(snapshot.data()?['blockedUsers'] ?? []);
    });
  }
  // Add to ChatProvider class

  // Enhanced block user functionality
  // Future<void> blockUser(String blockedUserId) async {
  //   final currentUser = _auth.currentUser;
  //   if (currentUser == null) return;

  //   try {
  //     await _firestore.collection('users').doc(currentUser.uid).set({
  //       'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     final chatId = getChatId(currentUser.uid, blockedUserId);
  //     await _firestore.collection('chats').doc(chatId).set({
  //       'lastMessage': '🚫 Contact blocked',
  //       'lastMessageTime': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     notifyListeners();
  //   } catch (e) {
  //     print('Error blocking user: $e');
  //     rethrow;
  //   }
  // }

  // Message selection and deletion
  Future<void> deleteMultipleMessages(
    String chatId,
    List<String> messageIds, {
    bool deleteForEveryone = false,
    String? currentUserId,
  }) async {
    final batch = _firestore.batch();

    for (var id in messageIds) {
      final docRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(id);

      if (deleteForEveryone) {
        // Replace with "deleted" text instead of removing
        batch.update(docRef, {
          'text': "🚫 This message was deleted",
          'mediaUrl': null,
          'messageType': 'deleted',
        });
      } else {
        // Delete only for me → add hiddenFor list
        batch.update(docRef, {
          'hiddenFor': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }

    await batch.commit();
  }

  // Check if user can receive messages (for showing single tick)
  Future<bool> canReceiveMessages(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // Check if current user has blocked receiver
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserBlockedUsers = List<String>.from(
        currentUserDoc.data()?['blockedUsers'] ?? [],
      );

      return !currentUserBlockedUsers.contains(receiverId);
    } catch (e) {
      print('Error checking receive permissions: $e');
      return false;
    }
  }
}

// lib/providers/chat_provider.dart
// import 'dart:convert';
// import 'package:chat_app/model/chatmodel.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;

// class ChatProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Replace with your actual FCM server key from Firebase Console
//   // Get it from: Firebase Console → Project Settings → Cloud Messaging → Server Key
//   static const String serverKey = "YOUR_ACTUAL_SERVER_KEY_HERE";

//   String getChatId(String user1, String user2) {
//     List<String> users = [user1, user2];
//     users.sort();
//     return "${users[0]}_${users[1]}";
//   }

//   // Get user status stream
//   Stream<Map<String, dynamic>> getUserStatusStream(String userId) {
//     return _firestore
//         .collection('users')
//         .doc(userId)
//         .snapshots()
//         .map((snapshot) => snapshot.data() ?? {});
//   }

//   // Update user's online status
//   Future<void> updateUserStatus(bool isOnline) async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'isOnline': isOnline,
//         'lastSeen': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }
//   }

//   // Save FCM token to user document
//   Future<void> saveUserFCMToken(String token) async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'fcmToken': token,
//         'tokenUpdatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }
//   }

//   // Get messages stream for a specific chat
//   Stream<List<MessageModel>> getMessagesStream(String chatId) {
//     return _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map(
//           (snapshot) =>
//               snapshot.docs
//                   .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
//                   .toList(),
//         );
//   }

//   // Send a message with notification
//   Future<void> sendMessage({
//     required String senderId,
//     required String receiverId,
//     required String text,
//     String? mediaUrl,
//     String messageType = 'text',
//     Map<String, dynamic>? contactInfo,
//   }) async {
//     if (text.trim().isEmpty && mediaUrl == null && contactInfo == null) return;

//     final chatId = getChatId(senderId, receiverId);

//     try {
//       final messageData = {
//         'senderId': senderId,
//         'receiverId': receiverId,
//         'text': text.trim(),
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//         'mediaUrl': mediaUrl,
//         'messageType': messageType,
//         if (contactInfo != null) 'contactInfo': contactInfo,
//       };

//       // Add message to messages subcollection
//       await _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .add(messageData);

//       // Update chat document with last message info
//       await _firestore.collection('chats').doc(chatId).set({
//         'lastMessage': _getDisplayText(text.trim(), messageType),
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         'participants': [senderId, receiverId],
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));

//       // Update unread count for receiver
//       await _updateUnreadCount(chatId, receiverId, true);

//       // Send push notification
//       await _sendNotificationToUser(
//         receiverId: receiverId,
//         senderId: senderId,
//         message:
//             text.trim().isNotEmpty
//                 ? text.trim()
//                 : _getDisplayText("", messageType),
//         messageType: messageType,
//       );

//       notifyListeners();
//     } catch (e) {
//       print('Error sending message: $e');
//       rethrow;
//     }
//   }

//   String _getDisplayText(String text, String messageType) {
//     if (text.isNotEmpty) return text;

//     switch (messageType) {
//       case 'image':
//         return '📷 Photo';
//       case 'audio':
//         return '🎤 Voice message';
//       case 'document':
//         return '📄 Document';
//       case 'contact':
//         return '👤 Contact';
//       default:
//         return 'Message';
//     }
//   }

//   // Send notification to user (individual chat)
//   Future<void> _sendNotificationToUser({
//     required String receiverId,
//     required String senderId,
//     required String message,
//     String messageType = 'text',
//   }) async {
//     try {
//       // Get receiver's FCM token and details
//       final receiverDoc =
//           await _firestore.collection('users').doc(receiverId).get();
//       final senderDoc =
//           await _firestore.collection('users').doc(senderId).get();

//       if (!receiverDoc.exists || !senderDoc.exists) {
//         print('User document not found');
//         return;
//       }

//       final fcmToken = receiverDoc.data()?['fcmToken'];
//       final senderName = senderDoc.data()?['name'] ?? 'Someone';
//       final senderImage = senderDoc.data()?['profileImage'] ?? '';
//       final receiverPhone = receiverDoc.data()?['phone'] ?? '';

//       if (fcmToken == null || fcmToken.isEmpty) {
//         print('No FCM token found for receiver');
//         return;
//       }

//       await sendPushNotification(
//         token: fcmToken,
//         title: senderName,
//         body: message,
//         data: {
//           'senderId': senderId,
//           'receiverId': receiverId,
//           'type': 'chat',
//           'name': senderName,
//           'image': senderImage,
//           'phone': receiverPhone,
//           'messageType': messageType,
//         },
//       );
//     } catch (e) {
//       print('Error sending notification to user: $e');
//     }
//   }

//   // Generic push notification sender
//   Future<void> sendPushNotification({
//     required String token,
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//   }) async {
//     if (serverKey.isEmpty ||
//         serverKey.contains('YOUR_ACTUAL_SERVER_KEY_HERE')) {
//       print('⚠️ FCM Server Key not configured properly');
//       print('Please get your server key from:');
//       print(
//         'Firebase Console → Project Settings → Cloud Messaging → Server Key',
//       );
//       return;
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('https://fcm.googleapis.com/fcm/send'),
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'key=$serverKey',
//         },
//         body: jsonEncode({
//           'to': token,
//           'notification': {
//             'title': title,
//             'body': body,
//             'sound': 'default',
//             'badge': '1',
//           },
//           'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK', ...data},
//           'priority': 'high',
//         }),
//       );

//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         if (kDebugMode) {
//           print(
//             "✅ Push notification sent successfully: ${responseData['success']}",
//           );
//         }
//       } else {
//         if (kDebugMode) {
//           print(
//             "❌ Failed to send push notification: ${response.statusCode} - ${response.body}",
//           );
//         }
//       }
//     } catch (e) {
//       print("❌ Error sending push notification: $e");
//     }
//   }

//   // ... rest of your ChatProvider methods (markMessagesAsRead, etc.)
//   Future<void> markMessagesAsRead(String chatId, String userId) async {
//     try {
//       final messages =
//           await _firestore
//               .collection('chats')
//               .doc(chatId)
//               .collection('messages')
//               .where('receiverId', isEqualTo: userId)
//               .where('isRead', isEqualTo: false)
//               .get();

//       if (messages.docs.isEmpty) return;

//       final batch = _firestore.batch();
//       for (final doc in messages.docs) {
//         batch.update(doc.reference, {'isRead': true});
//       }

//       await batch.commit();

//       // Reset unread count for this user
//       await _updateUnreadCount(chatId, userId, false);

//       notifyListeners();
//     } catch (e) {
//       print('Error marking messages as read: $e');
//       rethrow;
//     }
//   }

//   // Update unread count
//   Future<void> _updateUnreadCount(
//     String chatId,
//     String userId,
//     bool increment,
//   ) async {
//     try {
//       final chatDoc = _firestore.collection('chats').doc(chatId);
//       final chatData = await chatDoc.get();

//       final unreadCounts = Map<String, dynamic>.from(
//         chatData.data()?['unreadCounts'] ?? {},
//       );

//       final currentCount = (unreadCounts[userId] ?? 0) as int;
//       unreadCounts[userId] = increment ? currentCount + 1 : 0;

//       await chatDoc.set({
//         'unreadCounts': unreadCounts,
//         'participants': [chatId.split('_')[0], chatId.split('_')[1]],
//       }, SetOptions(merge: true));
//     } catch (e) {
//       print('Error updating unread count: $e');
//       rethrow;
//     }
//   }

//   // Get unread messages count for a user across all chats
//   Stream<int> getUnreadCount(String userId) {
//     return _firestore
//         .collection('chats')
//         .where('participants', arrayContains: userId)
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs.fold(0, (total, doc) {
//             final unreadCounts = Map<String, dynamic>.from(
//               doc.data()['unreadCounts'] ?? {},
//             );
//             return total + (unreadCounts[userId] ?? 0) as int;
//           }),
//         );
//   }

//   // Get chat list for a user
//   Stream<List<Map<String, dynamic>>> getChats(String userId) {
//     return _firestore
//         .collection('chats')
//         .where('participants', arrayContains: userId)
//         .orderBy('updatedAt', descending: true)
//         .snapshots()
//         .map(
//           (snapshot) =>
//               snapshot.docs
//                   .map((doc) => {'chatId': doc.id, ...doc.data()})
//                   .toList(),
//         );
//   }

//   // Delete a single message
//   Future<void> deleteMessage(String chatId, String messageId) async {
//     try {
//       await _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .doc(messageId)
//           .delete();

//       notifyListeners();
//     } catch (e) {
//       print('Error deleting message: $e');
//       rethrow;
//     }
//   }

//   // Delete multiple messages
//   Future<void> deleteMessages(String chatId, List<String> messageIds) async {
//     try {
//       final batch = _firestore.batch();
//       for (final id in messageIds) {
//         final docRef = _firestore
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .doc(id);
//         batch.delete(docRef);
//       }
//       await batch.commit();
//       notifyListeners();
//     } catch (e) {
//       print('Error deleting messages: $e');
//       rethrow;
//     }
//   }

// }
