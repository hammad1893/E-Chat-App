import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UnreadCountProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _individualUnreadCount = 0;
  int _groupUnreadCount = 0;

  StreamSubscription? _individualSubscription;
  StreamSubscription? _groupSubscription;

  int get individualUnreadCount => _individualUnreadCount;
  int get groupUnreadCount => _groupUnreadCount;
  int get totalUnreadCount => _individualUnreadCount + _groupUnreadCount;

  UnreadCountProvider() {
    _initializeStreams();
  }

  void _initializeStreams() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen to individual chats
    _individualSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
          int individualTotal = 0;
          int groupTotal = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final isGroup = data['isGroup'] == true;
            final unreadCounts = Map<String, dynamic>.from(
              data['unreadCounts'] ?? {},
            );

            final count = unreadCounts[userId];
            final unreadCount =
                count is int ? count : (count is num ? count.toInt() : 0);

            if (isGroup) {
              groupTotal += unreadCount;
            } else {
              individualTotal += unreadCount;
            }
          }

          bool changed = false;
          if (_individualUnreadCount != individualTotal) {
            _individualUnreadCount = individualTotal;
            changed = true;
          }
          if (_groupUnreadCount != groupTotal) {
            _groupUnreadCount = groupTotal;
            changed = true;
          }

          if (changed) {
            notifyListeners();
            print(
              '📊 Unread counts updated: Individual=$individualTotal, Groups=$groupTotal',
            );
          }
        });
  }

  // Get unread count for specific chat
  Stream<int> getChatUnreadCount(String chatId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return 0;

      final data = doc.data();
      if (data == null) return 0;

      final unreadCounts = Map<String, dynamic>.from(
        data['unreadCounts'] ?? {},
      );

      final count = unreadCounts[userId];
      return count is int ? count : (count is num ? count.toInt() : 0);
    });
  }

  @override
  void dispose() {
    _individualSubscription?.cancel();
    _groupSubscription?.cancel();
    super.dispose();
  }
}
