import 'package:cloud_firestore/cloud_firestore.dart';

class AuthModel {
  String? id;
  String? name;
  String? email;
  String? passwordHash;
  String? phoneNumber;
  String? profilePicture;
  String? dob;
  String? gender;
  DateTime? timestamp;
  DateTime? updatedAt;

  AuthModel({
    this.id,
    this.name,
    this.email,
    this.passwordHash,
    this.phoneNumber,
    this.profilePicture,
    this.dob,
    this.gender,
    this.timestamp,
    this.updatedAt,
  });

  AuthModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? gender,
    String? dob,
    String? updatedAt,
  }) {
    return AuthModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      passwordHash: passwordHash,
      dob: dob,
      gender: gender,
      timestamp: timestamp,
      updatedAt: timestamp ?? this.updatedAt,
    );
  }

  AuthModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    passwordHash = json['passwordHash'];
    phoneNumber = json['phoneNumber'];
    profilePicture = json['profilePicture'];
    dob = json['dob'];
    gender = json['gender'];

    // ✅ Convert Firestore Timestamps to DateTime
    timestamp =
        json['timestamp'] != null
            ? (json['timestamp'] as Timestamp).toDate()
            : null;

    updatedAt =
        json['updatedAt'] != null
            ? (json['updatedAt'] as Timestamp).toDate()
            : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'dob': dob,
      'gender': gender,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
