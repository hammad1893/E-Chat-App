// models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroup {
  final String groupId;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> adminIds;
  final List<String> memberIds;
  final String? imageUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int>? unreadCounts;

  // Fixed constructor with proper parameter order
  ChatGroup({
    required this.groupId,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
    this.description,
    this.adminIds = const [],
    this.imageUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCounts,
  });

  factory ChatGroup.fromMap(Map<String, dynamic> map, String id) {
    try {
      return ChatGroup(
        groupId: id,
        name: map['name']?.toString() ?? '',
        description: map['description']?.toString(),
        createdBy: map['createdBy']?.toString() ?? '',
        createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
        memberIds: _parseStringList(map['memberIds']),
        adminIds: _parseStringList(map['adminIds']),
        imageUrl: map['imageUrl']?.toString(),
        lastMessage: map['lastMessage']?.toString(),
        lastMessageTime: _parseTimestamp(map['lastMessageTime']),
        unreadCounts: _parseUnreadCounts(map['unreadCounts']),
      );
    } catch (e) {
      print('Error parsing ChatGroup from map: $e');
      return ChatGroup(
        groupId: id,
        name: 'Unknown Group',
        createdBy: '',
        createdAt: DateTime.now(),
        memberIds: [],
        adminIds: [],
        unreadCounts: {},
      );
    }
  }

  static DateTime? _parseTimestamp(dynamic timestampData) {
    try {
      if (timestampData == null) return null;
      if (timestampData is Timestamp) {
        return timestampData.toDate();
      }
      if (timestampData is DateTime) {
        return timestampData;
      }
      return null;
    } catch (e) {
      print('Error parsing timestamp: $e');
      return null;
    }
  }

  static List<String> _parseStringList(dynamic listData) {
    try {
      if (listData == null) return [];
      if (listData is List) {
        return listData.map((item) => item.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing string list: $e');
      return [];
    }
  }

  // Fixed: Added proper parsing for unreadCounts
  static Map<String, int>? _parseUnreadCounts(dynamic unreadData) {
    try {
      if (unreadData == null) return null;
      if (unreadData is Map) {
        return Map<String, int>.from(
          unreadData.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ),
        );
      }
      return null;
    } catch (e) {
      print('Error parsing unread counts: $e');
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'memberIds': memberIds,
        'adminIds': adminIds,
        'imageUrl': imageUrl,
        if (lastMessage != null) 'lastMessage': lastMessage,
        if (lastMessageTime != null)
          'lastMessageTime': Timestamp.fromDate(lastMessageTime!),
        if (unreadCounts != null) 'unreadCounts': unreadCounts,
      };
    } catch (e) {
      print('Error converting ChatGroup to map: $e');
      return {
        'name': name,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'memberIds': memberIds,
        'adminIds': adminIds,
      };
    }
  }

  int get memberCount => memberIds.length;
  bool isUserAdmin(String userId) => adminIds.contains(userId);
  bool isUserMember(String userId) => memberIds.contains(userId);

  ChatGroup copyWith({
    String? groupId,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? adminIds,
    List<String>? memberIds,
    String? imageUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
  }) {
    return ChatGroup(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }
}
