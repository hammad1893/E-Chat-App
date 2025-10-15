// models/group_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessageModel {
  final String? senderId;
  final String? senderName;
  final String? text;
  final dynamic timestamp;
  final bool? isRead;
  final bool? isDelivered;
  final String? mediaUrl;
  final String? messageType;
  final Map<String, dynamic>? contactInfo;
  final String? messageId;
  final List<String>? deletedFor;

  GroupMessageModel({
    this.senderId,
    this.senderName,
    this.text,
    this.timestamp,
    this.isRead,
    this.isDelivered,
    this.mediaUrl,
    this.messageType,
    this.contactInfo,
    this.messageId,
    this.deletedFor,
  });

  factory GroupMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupMessageModel(
      senderId: map['senderId'],
      senderName: map['senderName'], // Ensure this field is mapped
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      messageType: map['messageType'],
      contactInfo:
          map['contactInfo'] != null
              ? Map<String, dynamic>.from(map['contactInfo'])
              : null,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'],
      isDelivered: map['isDelivered'],
      messageId: id,
      deletedFor:
          map['deletedFor'] != null ? List<String>.from(map['deletedFor']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName, // Ensure this field is included
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp ?? DateTime.now()),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'mediaUrl': mediaUrl,
      'messageType': messageType,
      'contactInfo': contactInfo,
      'messageId': messageId,
    };
  }
}
