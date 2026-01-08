// state/chatstate.dart
import 'package:chat_app/model/chatmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ✅ ADD: Message cache per chat
  final Map<String, List<MessageModel>> _messageCache = {};
  final Map<String, Stream<List<MessageModel>>> _streamCache = {};

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
    // ✅ RETURN CACHED STREAM if available
    if (_streamCache.containsKey(chatId)) {
      return _streamCache[chatId]!;
    }

    // ✅ CREATE NEW STREAM and cache it
    final stream =
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .asyncMap((snapshot) async {
              // Quick processing without heavy operations
              final messages =
                  snapshot.docs
                      .map((doc) {
                        final data = doc.data();
                        if (data['hiddenFor'] != null &&
                            (data['hiddenFor'] as List).contains(
                              currentUserId,
                            )) {
                          return null;
                        }
                        return MessageModel.fromMap(data, doc.id);
                      })
                      .whereType<MessageModel>()
                      .toList();

              // ✅ UPDATE CACHE
              _messageCache[chatId] = messages;

              return messages;
            })
            .asBroadcastStream();

    // ✅ CACHE THE STREAM
    _streamCache[chatId] = stream;

    return stream;
  }
  
  List<MessageModel>? getCachedMessages(String chatId) {
    return _messageCache[chatId];
  }

  // ✅ CLEAR CACHE when needed
  void clearMessageCache(String chatId) {
    _messageCache.remove(chatId);
    _streamCache.remove(chatId);
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
      // ❌ If I blocked them, I cannot send
      final iBlockedThem = await isUserBlocked(receiverId);
      if (iBlockedThem) {
        return false;
      }

      // ✅ If they blocked me, I can still send (messages just won't deliver)
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
      // ✅ Check if SENDER has blocked receiver - DON'T allow sending
      final iBlockedReceiver = await isUserBlocked(receiverId);
      if (iBlockedReceiver) {
        throw 'You have blocked this contact. Unblock to send messages.';
      }

      // ✅ Check if receiver has blocked sender - ALLOW sending but mark as undelivered
      final isReceiverBlockingMe = await isBlockedByUser(receiverId);

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
        'delivered': !isReceiverBlockingMe,
      };
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Prepare last message text
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

      // ✅ Update chat document
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
        'blockedBy': isReceiverBlockingMe ? receiverId : null,
        'hiddenFor': isReceiverBlockingMe ? [receiverId] : [],
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          senderId: 0,
          receiverId: isReceiverBlockingMe ? 0 : FieldValue.increment(1),
        },
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

  Future<bool> isUserBlocked(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final blockedUsers = List<String>.from(
        userDoc.data()?['blockedUsers'] ?? [],
      );
      print(
        '🔵 Checking if user $otherUserId is blocked by ${currentUser.uid}: ${blockedUsers.contains(otherUserId)}',
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
      print("Blocked users: ${snapshot.data()?['blockedUsers']}");
      return List<String>.from(snapshot.data()?['blockedUsers'] ?? []);
    });
  }

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
