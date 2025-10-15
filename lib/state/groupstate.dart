import 'package:chat_app/model/groupmessagemodel.dart';
import 'package:chat_app/model/groupmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GroupProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate inputs
      if (name.trim().isEmpty) {
        throw Exception('Group name cannot be empty');
      }

      if (memberIds.isEmpty) {
        throw Exception('At least one member is required');
      }
      final updatedMemberIds = List<String>.from(memberIds);
      if (!updatedMemberIds.contains(currentUser.uid)) {
        updatedMemberIds.add(currentUser.uid);
      }
      final groupDoc = _firestore.collection('groups').doc();
      final groupId = groupDoc.id;

      print('Creating group with ID: $groupId');
      final chatGroup = ChatGroup(
        groupId: groupId,
        name: name.trim(),
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        memberIds: updatedMemberIds,
        description: description?.trim(),
        adminIds: [currentUser.uid],
        imageUrl: imageUrl,
      );
      await groupDoc.set(chatGroup.toMap());
      print('Group document created successfully');
      final chatData = {
        'lastMessage': 'Group created',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': updatedMemberIds,
        'isGroup': true,
        'groupName': name.trim(),
        'groupImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': _initializeUnreadCounts(
          updatedMemberIds,
          currentUser.uid,
        ),
      };

      await _firestore.collection('chats').doc(groupId).set(chatData);
      print('Chat document created successfully');

      notifyListeners();
      return groupId;
    } catch (e) {
      print('Error creating group: $e');
      if (e is FirebaseException) {
        throw Exception('Firebase error: ${e.message}');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Unknown error occurred while creating group: $e');
      }
    }
  }

  // Helper method to initialize unread counts
  Map<String, int> _initializeUnreadCounts(
    List<String> memberIds,
    String senderId,
  ) {
    final counts = <String, int>{};
    for (final memberId in memberIds) {
      counts[memberId] = memberId == senderId ? 0 : 1;
    }
    return counts;
  }

  // Get user's groups
  Stream<List<ChatGroup>> getUserGroups() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('No authenticated user found');
      return Stream.value([]);
    }

    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final groups = <ChatGroup>[];
          print('Processing ${snapshot.docs.length} groups');

          for (final doc in snapshot.docs) {
            try {
              final groupData = doc.data();
              if (groupData.isEmpty) {
                print('Empty group data for ${doc.id}');
                continue;
              }

              // Get the last message from the chat document
              final chatDoc =
                  await _firestore.collection('chats').doc(doc.id).get();
              String? lastMessage;
              DateTime? lastMessageTime;

              if (chatDoc.exists) {
                final chatData = chatDoc.data();
                if (chatData != null) {
                  lastMessage = chatData['lastMessage']?.toString();
                  final timestamp = chatData['lastMessageTime'];
                  if (timestamp is Timestamp) {
                    lastMessageTime = timestamp.toDate();
                  }
                }
              }

              // Merge group data with last message info
              final completeGroupData = {
                ...groupData,
                if (lastMessage != null) 'lastMessage': lastMessage,
                if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
              };

              final group = ChatGroup.fromMap(completeGroupData, doc.id);
              groups.add(group);
            } catch (e) {
              print('Error processing group ${doc.id}: $e');
              // Continue processing other groups instead of failing completely
            }
          }

          print('Successfully processed ${groups.length} groups');
          return groups;
        })
        .handleError((error) {
          print('Error in getUserGroups stream: $error');
          return <ChatGroup>[]; // Return empty list on error
        });
  }

  // Get group details
  Stream<ChatGroup?> getGroup(String groupId) {
    if (groupId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
          try {
            if (!snapshot.exists) {
              print('Group $groupId not found');
              return null;
            }

            final data = snapshot.data();
            if (data == null) {
              print('Group $groupId has null data');
              return null;
            }

            return ChatGroup.fromMap(data, snapshot.id);
          } catch (e) {
            print('Error parsing group $groupId: $e');
            return null;
          }
        })
        .handleError((error) {
          print('Error in getGroup stream: $error');
          return null;
        });
  }

  // Add members to group
  Future<void> addMembersToGroup(
    String groupId,
    List<String> newMemberIds,
  ) async {
    try {
      if (groupId.isEmpty) {
        throw Exception('Group ID cannot be empty');
      }

      if (newMemberIds.isEmpty) {
        throw Exception('No members to add');
      }

      final groupDoc = _firestore.collection('groups').doc(groupId);
      final groupSnapshot = await groupDoc.get();

      if (!groupSnapshot.exists) {
        throw Exception('Group does not exist');
      }

      final groupData = groupSnapshot.data();
      if (groupData == null) {
        throw Exception('Group data is null');
      }

      final currentMembers = List<String>.from(groupData['memberIds'] ?? []);

      // Filter out members that are already in the group
      final membersToAdd =
          newMemberIds
              .where((memberId) => !currentMembers.contains(memberId))
              .toList();

      if (membersToAdd.isEmpty) {
        print('All specified members are already in the group');
        return;
      }

      final updatedMembers = [...currentMembers, ...membersToAdd];

      await groupDoc.update({'memberIds': updatedMembers});

      // Also update the chat document
      final chatDoc = _firestore.collection('chats').doc(groupId);
      final chatSnapshot = await chatDoc.get();

      if (chatSnapshot.exists) {
        final chatData = chatSnapshot.data();
        if (chatData != null) {
          final unreadCounts = Map<String, int>.from(
            chatData['unreadCounts'] ?? {},
          );

          // Initialize unread counts for new members
          for (final newMemberId in membersToAdd) {
            unreadCounts[newMemberId] = 0;
          }

          await chatDoc.update({
            'participants': updatedMembers,
            'unreadCounts': unreadCounts,
          });
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error adding members to group: $e');
      rethrow;
    }
  }

  // Send message to group
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    String? mediaUrl,
    String messageType = 'text',
    Map<String, dynamic>? contactInfo,
  }) async {
    try {
      if (groupId.isEmpty) {
        throw Exception('Group ID cannot be empty');
      }

      if (text.trim().isEmpty && mediaUrl == null && contactInfo == null) {
        throw Exception('Message content cannot be empty');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if group exists
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group does not exist');
      }

      final messageData = {
        'groupId': groupId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Unknown User',
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': true,
        'mediaUrl': mediaUrl,
        'messageType': messageType,
        'readBy': {currentUser.uid: true},
        if (contactInfo != null) 'contactInfo': contactInfo,
      };

      // Add message
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(messageData);

      // Prepare last message text
      String lastMessageText = text.trim();
      if (lastMessageText.isEmpty) {
        switch (messageType) {
          case 'image':
            lastMessageText = '📷 Photo';
            break;
          case 'audio':
            lastMessageText = '🎤 Voice message';
            break;
          case 'document':
            lastMessageText = '📄 Document';
            break;
          case 'contact':
            lastMessageText = '📞 Contact';
            break;
          default:
            lastMessageText = 'Media';
        }
      }

      // ✅ Get current group members
      final groupData = groupDoc.data();
      final memberIds = List<String>.from(groupData?['memberIds'] ?? []);

      // ✅ Build unread counts map
      final Map<String, dynamic> unreadCounts = {};
      for (final memberId in memberIds) {
        if (memberId == currentUser.uid) {
          unreadCounts[memberId] = 0; // Sender has 0 unread
        } else {
          unreadCounts[memberId] = FieldValue.increment(1);
        }
      }

      // ✅ Update chat document with proper structure
      await _firestore.collection('chats').doc(groupId).set({
        'lastMessage': lastMessageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isGroup': true, // ✅ Mark as group chat
        'groupName': groupData?['name'] ?? 'Group',
        'participants': memberIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts, // ✅ Update unread counts properly
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      print('Error sending group message: $e');
      rethrow;
    }
  }

  Future<void> sendGroupSystemMessage({
    required String groupId,
    required String text,
    String? mediaUrl,
    String messageType = 'text',
    Map<String, dynamic>? contactInfo,
  }) async {
    try {
      if (groupId.isEmpty) {
        throw Exception('Group ID cannot be empty');
      }

      if (text.trim().isEmpty && mediaUrl == null && contactInfo == null) {
        throw Exception('Message content cannot be empty');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if group exists
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group does not exist');
      }

      // ✅ Fetch actual user name from Firestore
      String senderName = 'Unknown User';
      try {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          senderName =
              userData?['name'] ?? userData?['phone'] ?? 'Unknown User';
        }
      } catch (e) {
        print('Error fetching sender name: $e');
      }

      final messageData = {
        'groupId': groupId,
        'senderId': currentUser.uid,
        'senderName': senderName, // ✅ Use fetched name
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': true,
        'mediaUrl': mediaUrl,
        'messageType': messageType,
        'readBy': {currentUser.uid: true},
        if (contactInfo != null) 'contactInfo': contactInfo,
      };
      // Add message
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(messageData);

      // Prepare last message text
      String lastMessageText = text.trim();
      if (lastMessageText.isEmpty) {
        switch (messageType) {
          case 'image':
            lastMessageText = '📷 Photo';
            break;
          case 'audio':
            lastMessageText = '🎤 Voice message';
            break;
          case 'document':
            lastMessageText = '📄 Document';
            break;
          case 'contact':
            lastMessageText = '📞 Contact';
            break;
          default:
            lastMessageText = 'Media';
        }
      }

      // ✅ Get current group members
      final groupData = groupDoc.data();
      final memberIds = List<String>.from(groupData?['memberIds'] ?? []);

      // ✅ Build unread counts map
      final Map<String, dynamic> unreadCounts = {};
      for (final memberId in memberIds) {
        if (memberId == currentUser.uid) {
          unreadCounts[memberId] = 0; // Sender has 0 unread
        } else {
          unreadCounts[memberId] = FieldValue.increment(1);
        }
      }

      // ✅ Update chat document with proper structure
      await _firestore.collection('chats').doc(groupId).set({
        'lastMessage': lastMessageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isGroup': true, // ✅ Mark as group chat
        'groupName': groupData?['name'] ?? 'Group',
        'participants': memberIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts, // ✅ Update unread counts properly
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      print('Error sending group message: $e');
      rethrow;
    }
  }

  // Get group messages stream
  Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    if (groupId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit messages for better performance
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    return GroupMessageModel.fromMap(data, doc.id);
                  } catch (e) {
                    print('Error parsing message ${doc.id}: $e');
                    return null;
                  }
                })
                .where((message) => message != null)
                .cast<GroupMessageModel>()
                .toList();
          } catch (e) {
            print('Error processing messages: $e');
            return <GroupMessageModel>[];
          }
        })
        .handleError((error) {
          print('Error in getGroupMessages stream: $error');
          return <GroupMessageModel>[];
        });
  }

  // Mark group messages as read
  // Mark group messages as read
  Future<void> markGroupMessagesAsRead(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No authenticated user');
      return;
    }

    if (groupId.isEmpty) {
      print('Group ID is empty');
      return;
    }

    try {
      print(
        '🔵 Marking group messages as read for group: $groupId, user: ${currentUser.uid}',
      );

      // Check if group exists
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        print('Group $groupId does not exist');
        return;
      }

      // Get unread messages
      final messages =
          await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .where('senderId', isNotEqualTo: currentUser.uid)
              .limit(100)
              .get();

      if (messages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        int markedCount = 0;

        for (final doc in messages.docs) {
          final data = doc.data();
          final readBy = Map<String, dynamic>.from(data['readBy'] ?? {});

          // Only update if not already read by current user
          if (readBy[currentUser.uid] != true) {
            batch.update(doc.reference, {'readBy.${currentUser.uid}': true});
            markedCount++;
          }
        }

        if (markedCount > 0) {
          await batch.commit();
          print('📧 Marked $markedCount group messages as read');
        }
      }

      // ✅ CRITICAL: Reset unread count to 0 in chat document
      await _firestore.collection('chats').doc(groupId).update({
        'unreadCounts.${currentUser.uid}': 0,
      });

      print('✅ Successfully reset group unread count');
      notifyListeners();
    } catch (e) {
      print('❌ Error marking group messages as read: $e');
    }
  }

  Stream<int> getGroupUnreadCount(String groupId, String userId) {
    if (groupId.isEmpty || userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chats')
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
          try {
            if (!snapshot.exists) return 0;

            final data = snapshot.data();
            if (data == null) return 0;

            final unreadCounts = Map<String, int>.from(
              data['unreadCounts'] ?? {},
            );
            return unreadCounts[userId] ?? 0;
          } catch (e) {
            print('Error getting unread count: $e');
            return 0;
          }
        })
        .handleError((error) {
          print('Error in getGroupUnreadCount stream: $error');
          return 0;
        });
  }

  // Delete group message
  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    try {
      if (groupId.isEmpty || messageId.isEmpty) {
        throw Exception('Group ID and Message ID cannot be empty');
      }

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

      notifyListeners();
    } catch (e) {
      print('Error deleting group message: $e');
      rethrow;
    }
  }

  // Update group info
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      if (groupId.isEmpty) {
        throw Exception('Group ID cannot be empty');
      }

      final updateData = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }
      if (description != null) {
        updateData['description'] = description.trim();
      }
      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      if (updateData.isEmpty) {
        print('No valid data to update');
        return;
      }

      await _firestore.collection('groups').doc(groupId).update(updateData);

      // Also update the chat document if name changed
      if (updateData.containsKey('name')) {
        await _firestore.collection('chats').doc(groupId).set({
          'groupName': updateData['name'],
        }, SetOptions(merge: true));
      }

      notifyListeners();
    } catch (e) {
      print('Error updating group info: $e');
      rethrow;
    }
  }

  // Check if user is group admin
  Future<bool> isUserAdmin(String groupId, String userId) async {
    try {
      if (groupId.isEmpty || userId.isEmpty) {
        return false;
      }

      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        return false;
      }

      final groupData = groupDoc.data();
      if (groupData == null) {
        return false;
      }

      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      return adminIds.contains(userId);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get group member details
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      if (groupId.isEmpty) {
        return [];
      }

      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        return [];
      }

      final groupData = groupDoc.data();
      if (groupData == null) {
        return [];
      }

      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);

      final members = <Map<String, dynamic>>[];

      for (final memberId in memberIds) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(memberId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            members.add({
              'uid': memberId,
              'name': userData['name'] ?? 'Unknown',
              'email': userData['email'] ?? '',
              'photoUrl': userData['photoUrl'],
              'isAdmin': adminIds.contains(memberId),
            });
          }
        } catch (e) {
          print('Error fetching user data for $memberId: $e');
        }
      }

      return members;
    } catch (e) {
      print('Error getting group members: $e');
      return [];
    }
  }

  // Delete multiple messages
  Future<void> deleteMultipleMessages(
    String groupId,
    List<String> messageIds,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (String messageId in messageIds) {
        DocumentReference docRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .doc(messageId);
        batch.delete(docRef);
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      print('Error deleting multiple messages: $e');
      throw e;
    }
  }
  // Add these methods to your GroupProvider class

  // Delete message for everyone (admin only)
  Future<void> deleteMessageForEveryone(
    String groupId,
    String messageId,
  ) async {
    try {
      if (groupId.isEmpty || messageId.isEmpty) {
        throw Exception('Group ID and Message ID cannot be empty');
      }

      // Check if user is admin
      final isAdmin = await isCurrentUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can delete messages for everyone');
      }

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

      notifyListeners();
    } catch (e) {
      print('Error deleting message for everyone: $e');
      rethrow;
    }
  }

  // Delete message only for current user
  // In GroupProvider, update the deleteForMe method:
  Future<void> deleteMessageForMe(String groupId, String messageId) async {
    try {
      if (groupId.isEmpty || messageId.isEmpty) {
        throw Exception('Group ID and Message ID cannot be empty');
      }

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // For group messages, we'll mark it as deleted for this user
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([currentUserId]),
          });

      notifyListeners();
    } catch (e) {
      print('Error deleting message for me: $e');
      rethrow;
    }
  }

  // Update deleteMultipleGroupMessages to handle the array properly:
  Future<void> deleteMultipleGroupMessages({
    required String groupId,
    required List<String> messageIds,
    required bool deleteForEveryone,
  }) async {
    try {
      if (groupId.isEmpty || messageIds.isEmpty) {
        throw Exception('Group ID and Message IDs cannot be empty');
      }

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      if (deleteForEveryone) {
        // Check if user is admin
        final isAdmin = await isCurrentUserAdmin(groupId);
        if (!isAdmin) {
          throw Exception('Only admins can delete messages for everyone');
        }

        // Delete messages completely
        final batch = _firestore.batch();
        for (final messageId in messageIds) {
          final docRef = _firestore
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .doc(messageId);
          batch.delete(docRef);
        }
        await batch.commit();
      } else {
        // Mark messages as deleted for current user only
        for (final messageId in messageIds) {
          await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .doc(messageId)
              .update({
                'deletedFor': FieldValue.arrayUnion([currentUserId]),
              });
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting multiple group messages: $e');
      rethrow;
    }
  }

  // Leave group (remove user from group)
  Future<void> leaveGroup(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Get current user data for the system message
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final userName = userDoc.data()?['name'] ?? 'User';

      // Get group data
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) return;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> memberIds = groupData['memberIds'] ?? [];
      List<dynamic> adminIds = groupData['adminIds'] ?? [];

      // Remove current user from members
      memberIds.remove(currentUserId);

      // Check if user is admin
      bool wasAdmin = adminIds.contains(currentUserId);
      if (wasAdmin) {
        adminIds.remove(currentUserId);

        // If user was the only admin, make the first member an admin
        if (adminIds.isEmpty && memberIds.isNotEmpty) {
          adminIds.add(memberIds[0]);
        }
      }

      // Update group if there are still members
      if (memberIds.isNotEmpty) {
        await _firestore.collection('groups').doc(groupId).update({
          'memberIds': memberIds,
          'adminIds': adminIds,
        });

        // Add a proper system message about user leaving
        await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .add({
              'text': '$userName left the group',
              'messageType': 'system', // Use 'system' type
              'timestamp': FieldValue.serverTimestamp(),
              'senderId': 'system', // Use 'system' as sender
              'isSystemMessage': true, // Add this flag
            });
      } else {
        // If no members left, delete the group and all related data
        await _firestore.collection('groups').doc(groupId).delete();
        await _firestore.collection('chats').doc(groupId).delete();

        // Also delete all messages from the group
        final messagesSnapshot =
            await _firestore
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .get();

        final batch = _firestore.batch();
        for (final doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      notifyListeners();
    } catch (e) {
      print('Error leaving group: $e');
      throw e;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) return false;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> adminIds = groupData['adminIds'] ?? [];

      return adminIds.contains(currentUserId);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Remove a member from group (admin only)
  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      // Check if current user is admin
      bool isAdmin = await isCurrentUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can remove members');
      }

      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) return;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> memberIds = groupData['memberIds'] ?? [];
      List<dynamic> adminIds = groupData['adminIds'] ?? [];

      // Remove the member
      memberIds.remove(memberId);
      adminIds.remove(memberId); // Also remove from admins if they were one

      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': memberIds,
        'adminIds': adminIds,
      });

      // Add system message
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
            'text': '${groupData['name']} was removed from the group',
            'messageType': 'system',
            'timestamp': FieldValue.serverTimestamp(),
            'senderId': 'system',
            'isSystemMessage': true,
          });

      notifyListeners();
    } catch (e) {
      print('Error removing member: $e');
      throw e;
    }
  }

  // Make a member admin
  Future<void> makeMemberAdmin(String groupId, String memberId) async {
    try {
      // Check if current user is admin
      bool isAdmin = await isCurrentUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can make other members admin');
      }

      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) return;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> adminIds = groupData['adminIds'] ?? [];

      // Add member to admins if not already
      if (!adminIds.contains(memberId)) {
        adminIds.add(memberId);

        await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .add({
              'text': '${groupData['name']} was made an admin',
              'messageType': 'system',
              'timestamp': FieldValue.serverTimestamp(),
              'senderId': 'system',
              'isSystemMessage': true,
            });

        notifyListeners();
      }
    } catch (e) {
      print('Error making member admin: $e');
      throw e;
    }
  }

  // Add to GroupProvider class
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Stream<Map<String, dynamic>> getUserDataStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      return snapshot.data() ?? {};
    });
  }

  // Add to GroupProvider class - Add members to group
  Future<void> addMembersToGroupWithSelection(
    String groupId,
    List<String> selectedMemberIds,
  ) async {
    try {
      if (groupId.isEmpty) {
        throw Exception('Group ID cannot be empty');
      }

      if (selectedMemberIds.isEmpty) {
        throw Exception('No members selected');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can add members to the group');
      }

      // Get current group data
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group does not exist');
      }

      final groupData = groupDoc.data();
      if (groupData == null) {
        throw Exception('Group data is null');
      }

      final currentMembers = List<String>.from(groupData['memberIds'] ?? []);

      // Filter out members that are already in the group
      final membersToAdd =
          selectedMemberIds
              .where((memberId) => !currentMembers.contains(memberId))
              .toList();

      if (membersToAdd.isEmpty) {
        throw Exception('All selected members are already in the group');
      }

      final updatedMembers = [...currentMembers, ...membersToAdd];

      // Update group members
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': updatedMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update chat document participants
      final chatDoc = _firestore.collection('chats').doc(groupId);
      final chatSnapshot = await chatDoc.get();

      if (chatSnapshot.exists) {
        final chatData = chatSnapshot.data();
        if (chatData != null) {
          final unreadCounts = Map<String, int>.from(
            chatData['unreadCounts'] ?? {},
          );

          // Initialize unread counts for new members
          for (final newMemberId in membersToAdd) {
            unreadCounts[newMemberId] = 0;
          }

          await chatDoc.set({
            'participants': updatedMembers,
            'unreadCounts': unreadCounts,
          }, SetOptions(merge: true));
        }
      }

      // Add system message about new members
      final userNames = <String>[];
      for (final memberId in membersToAdd) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(memberId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            final userName = userData?['name'] ?? 'User';
            userNames.add(userName);
          }
        } catch (e) {
          print('Error fetching user name for $memberId: $e');
        }
      }

      final addedMembersText =
          userNames.isNotEmpty ? userNames.join(', ') : 'New members';

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
            'text': '$addedMembersText were added to the group',
            'messageType': 'system',
            'timestamp': FieldValue.serverTimestamp(),
            'senderId': 'system',
            'isSystemMessage': true,
          });

      // Update last message in chat
      await _firestore.collection('chats').doc(groupId).set({
        'lastMessage': 'Members added to group',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      print('Error adding members to group: $e');
      rethrow;
    }
  }

  // Get available contacts (users who are not already in the group)
  Stream<List<Map<String, dynamic>>> getAvailableContacts(String groupId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore.collection('groups').doc(groupId).snapshots().asyncMap((
      groupSnapshot,
    ) async {
      if (!groupSnapshot.exists) return [];

      final groupData = groupSnapshot.data();
      final currentMemberIds = List<String>.from(groupData?['memberIds'] ?? []);

      // Get all users except current group members
      final allUsersSnapshot = await _firestore.collection('users').get();

      return allUsersSnapshot.docs
          .where((userDoc) {
            final userId = userDoc.id;
            return userId != currentUserId &&
                !currentMemberIds.contains(userId);
          })
          .map((userDoc) {
            final userData = userDoc.data();
            return {
              'uid': userDoc.id,
              'name': userData['name'] ?? 'Unknown',
              'email': userData['email'] ?? '',
              'phone': userData['phone'] ?? '',
              'photoUrl': userData['photoUrl'],
              'isSelected': false,
            };
          })
          .toList();
    });
  }
}
