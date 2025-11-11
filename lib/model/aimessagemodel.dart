import 'package:cloud_firestore/cloud_firestore.dart';

class AiMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp,
  };

  factory AiMessage.fromJson(Map<String, dynamic> json, String id) {
    return AiMessage(
      id: id,
      text: json['text'],
      isUser: json['isUser'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  // Helper method to check if message is from today
  bool get isFromToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  // Helper method to format date for display
  String get formattedDate {
    if (isFromToday) {
      return 'Today';
    } else {
      final difference = DateTime.now().difference(timestamp).inDays;
      if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    }
  }
}
