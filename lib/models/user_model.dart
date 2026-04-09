import 'package:flutter/foundation.dart';

enum UserRole { student, recruiter }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;
  final String? resumeUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.resumeUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] == 'recruiter' ? UserRole.recruiter : UserRole.student,
      profileImageUrl: json['profileImageUrl'] as String?,
      resumeUrl: json['resumeUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role == UserRole.recruiter ? 'recruiter' : 'student',
      'profileImageUrl': profileImageUrl,
      'resumeUrl': resumeUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    ValueGetter<String?>? profileImageUrl,
    ValueGetter<String?>? resumeUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl:
          profileImageUrl != null ? profileImageUrl() : this.profileImageUrl,
      resumeUrl: resumeUrl != null ? resumeUrl() : this.resumeUrl,
    );
  }
}
