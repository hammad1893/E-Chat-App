// // providers/ai_chat_provider.dart
// import 'package:chat_app/model/aimessagemodel.dart';
// import 'package:chat_app/services/gemini_services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

// class AiChatProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String userId;

//   AiChatProvider(this.userId);

//   // Stream for AI messages
//   Stream<List<AiMessage>> getMessages() {
//     // Calculate 15 days ago timestamp
//     final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15));

//     return _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('ai_chats')
//         .where('timestamp', isGreaterThanOrEqualTo: fifteenDaysAgo)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => AiMessage.fromJson(doc.data(), doc.id))
//             .toList());
//   }

//   // Send user message and get AI response
//   Future<void> sendMessage(String text) async {
//     try {
//       // Add user message
//       final userMessage = AiMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         text: text,
//         isUser: true,
//         timestamp: DateTime.now(),
//       );

//       await _firestore
//           .collection('users')
//           .doc(userId)
//           .collection('ai_chats')
//           .doc(userMessage.id)
//           .set(userMessage.toJson());

//       // Get AI response (you'll need to integrate your Gemini service here)
//       final aiResponse = await GeminiService.sendMessage(text);

//       // Add AI response
//       final aiMessage = AiMessage(
//         id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
//         text: aiResponse,
//         isUser: false,
//         timestamp: DateTime.now(),
//       );

//       await _firestore
//           .collection('users')
//           .doc(userId)
//           .collection('ai_chats')
//           .doc(aiMessage.id)
//           .set(aiMessage.toJson());

//     } catch (e) {
//       print('Error sending message: $e');
//       rethrow;
//     }
//   }

//   // Clean up messages older than 15 days
//   Future<void> cleanupOldMessages() async {
//     try {
//       final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15));

//       final oldMessages = await _firestore
//           .collection('users')
//           .doc(userId)
//           .collection('ai_chats')
//           .where('timestamp', isLessThan: fifteenDaysAgo)
//           .get();

//       // Delete in batches to avoid too many operations
//       final batch = _firestore.batch();
//       for (final doc in oldMessages.docs) {
//         batch.delete(doc.reference);
//       }

//       await batch.commit();
//     } catch (e) {
//       print('Error cleaning up old messages: $e');
//     }
//   }

//   // Clear all chat history
//   Future<void> clearChatHistory() async {
//     try {
//       final messages = await _firestore
//           .collection('users')
//           .doc(userId)
//           .collection('ai_chats')
//           .get();

//       final batch = _firestore.batch();
//       for (final doc in messages.docs) {
//         batch.delete(doc.reference);
//       }

//       await batch.commit();
//     } catch (e) {
//       print('Error clearing chat history: $e');
//       rethrow;
//     }
//   }
// }
// providers/ai_chat_provider.dart
import 'package:chat_app/model/aimessagemodel.dart';
import 'package:chat_app/services/gemini_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AiChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  // Cache for messages
  List<AiMessage> _cachedMessages = [];
  bool _isLoading = false;
  bool _hasCachedData = false;
  
  AiChatProvider(this.userId) {
    // Load cache immediately in constructor
    _loadCachedMessages();
  }

  bool get isLoading => _isLoading;
  bool get hasCachedData => _hasCachedData;

  // Load messages from cache - make it synchronous for instant access
  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('ai_chats_$userId');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _cachedMessages = jsonList.map((json) => 
          AiMessage.fromJson(Map<String, dynamic>.from(json), '')
        ).toList();
        _hasCachedData = true;
        notifyListeners(); // Notify immediately when cache is loaded
      }
    } catch (e) {
      print('Error loading cached messages: $e');
    }
  }

  // Save messages to cache
  Future<void> _saveMessagesToCache(List<AiMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      await prefs.setString('ai_chats_$userId', jsonEncode(jsonList));
      _cachedMessages = messages;
      _hasCachedData = true;
    } catch (e) {
      print('Error saving messages to cache: $e');
    }
  }

  // Stream for AI messages with caching
  Stream<List<AiMessage>> getMessages() {
    // Calculate 15 days ago timestamp
    final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15));
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ai_chats')
        .where('timestamp', isGreaterThanOrEqualTo: fifteenDaysAgo)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final messages = snapshot.docs
              .map((doc) => AiMessage.fromJson(doc.data(), doc.id))
              .toList();
          
          // Save to cache whenever we get new data
          if (messages.isNotEmpty) {
            await _saveMessagesToCache(messages);
          }
          
          return messages;
        });
  }

  // Get cached messages for instant display - NOW INSTANT!
  List<AiMessage> getCachedMessages() {
    return _cachedMessages;
  }

  // Send user message and get AI response
  Future<void> sendMessage(String text) async {
    try {
      setLoading(true);
      
      // Add user message to Firestore
      final userMessage = AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .doc(userMessage.id)
          .set(userMessage.toJson());

      // Update cache immediately for better UX
      _cachedMessages.insert(0, userMessage);
      await _saveMessagesToCache(_cachedMessages);

      // Get AI response
      final aiResponse = await GeminiService.sendMessage(text);
      
      // Add AI response to Firestore
      final aiMessage = AiMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .doc(aiMessage.id)
          .set(aiMessage.toJson());

      // Update cache with AI response
      _cachedMessages.insert(0, aiMessage);
      await _saveMessagesToCache(_cachedMessages);

    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clean up messages older than 15 days
  Future<void> cleanupOldMessages() async {
    try {
      final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15));
      
      final oldMessages = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .where('timestamp', isLessThan: fifteenDaysAgo)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Also clean cache
      _cachedMessages.removeWhere((msg) => msg.timestamp.isBefore(fifteenDaysAgo));
      await _saveMessagesToCache(_cachedMessages);
      
    } catch (e) {
      print('Error cleaning up old messages: $e');
    }
  }

  // Clear all chat history
  Future<void> clearChatHistory() async {
    try {
      final messages = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Clear cache
      _cachedMessages.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_chats_$userId');
      _hasCachedData = false;
      notifyListeners();
      
    } catch (e) {
      print('Error clearing chat history: $e');
      rethrow;
    }
  }
}