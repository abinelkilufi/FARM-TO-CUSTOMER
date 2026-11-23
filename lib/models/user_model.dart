import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, trader, consumer }

extension UserRoleExtension on UserRole {
  String get value => name;

  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer (Mkulima)';
      case UserRole.trader:
        return 'Trader (Mfanyabiashara)';
      case UserRole.consumer:
        return 'Consumer (Mteja)';
    }
  }
}

UserRole userRoleFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'farmer':
      return UserRole.farmer;
    case 'trader':
    case 'traders':
      return UserRole.trader;
    case 'consumer':
    default:
      return UserRole.consumer;
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String location;
  final String? profileImageUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.location,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final resolvedUid = (docId != null && docId.isNotEmpty)
        ? docId
        : (map['uid'] as String? ?? '');

    return UserModel(
      uid: resolvedUid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: userRoleFromString(map['role'] as String?),
      location: map['location'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? location,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
    );
  }
}
