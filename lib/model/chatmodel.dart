// models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  final bool isRead;
  final String? mediaUrl;
  final String messageType;
  final Map<String, dynamic>? contactInfo;
  final String? messageId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl,
    this.messageType = 'text',
    this.contactInfo,
    required this.messageId,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'],
      messageType: map['messageType'] ?? 'text',
      contactInfo:
          map['contactInfo'] != null
              ? Map<String, dynamic>.from(map['contactInfo'])
              : null,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      messageId: map['messageId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'messageType': messageType,
      'contactInfo': contactInfo,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageId': messageId,
    };
  }
}
