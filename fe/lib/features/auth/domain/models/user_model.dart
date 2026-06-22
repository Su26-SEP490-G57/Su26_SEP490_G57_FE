import 'package:equatable/equatable.dart';

enum UserRole { admin, headNurse, nurse, patient }

extension UserRoleX on UserRole {
  String get displayName => switch (this) {
    UserRole.admin => 'Quản trị viên',
    UserRole.headNurse => 'Điều dưỡng trưởng',
    UserRole.nurse => 'Điều dưỡng',
    UserRole.patient => 'Bệnh nhân',
  };

  bool get isAdmin => this == UserRole.admin;
  bool get isHeadNurse => this == UserRole.headNurse;
  bool get isNurse => this == UserRole.nurse;
  bool get isPatient => this == UserRole.patient;

  static UserRole fromString(String value) {
    return switch (value) {
      'Admin' => UserRole.admin,
      'Head_Nurse' => UserRole.headNurse,
      'Nurse' => UserRole.nurse,
      'Patient' => UserRole.patient,
      _ => throw ArgumentError('Unknown role: $value'),
    };
  }

  String get backendValue => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.headNurse => 'Head_Nurse',
    UserRole.nurse => 'Nurse',
    UserRole.patient => 'Patient',
  };
}

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.roles,
    required this.isActive,
    this.phoneNumber,
    this.caseId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String username;
  final String fullName;
  final List<UserRole> roles;
  final bool isActive;
  final String? phoneNumber;
  final String? caseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserRole get primaryRole => roles.isNotEmpty ? roles.first : UserRole.nurse;

  String get displayName => fullName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => UserRoleX.fromString(r as String))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      phoneNumber: json['phoneNumber'] as String?,
      caseId: json['caseId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'roles': roles.map((r) => r.backendValue).toList(),
    'isActive': isActive,
    'phoneNumber': phoneNumber,
    'caseId': caseId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  String get initials {
    if (fullName.isNotEmpty) {
      final parts = fullName.trim().split(' ');

      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }

      return fullName[0].toUpperCase();
    }

    return username[0].toUpperCase();
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? fullName,
    List<UserRole>? roles,
    bool? isActive,
    String? phoneNumber,
    String? caseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      caseId: caseId ?? this.caseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    fullName,
    roles,
    isActive,
    phoneNumber,
    caseId,
    createdAt,
    updatedAt,
  ];
}
