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
    this.dob,
    this.cityProvince,
    this.ward,
    this.detailedAddress,
    this.caseId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => UserRoleX.fromString(r as String))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      phoneNumber: json['phoneNumber'] as String?,
      dob: json['dob'] as String?,
      cityProvince: json['cityProvince'] as String?,
      ward: json['ward'] as String?,
      detailedAddress: json['detailedAddress'] as String?,
      caseId: json['caseId'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  final int id;
  final String username;
  final String fullName;
  final List<UserRole> roles;
  final bool isActive;
  final String? phoneNumber;
  final String? dob;
  final String? cityProvince;
  final String? ward;
  final String? detailedAddress;
  final String? caseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  UserRole get primaryRole => roles.isNotEmpty ? roles.first : UserRole.nurse;

  String get displayName => fullName;
  String? get formattedDob {
    if (dob == null || dob!.isEmpty) {
      return null;
    }

    final parts = dob!.split('-');

    if (parts.length != 3) {
      return dob;
    }

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String? get fullAddress {
    final parts = [
      detailedAddress,
      ward,
      cityProvince,
    ].where((e) => e != null && e.trim().isNotEmpty).cast<String>();

    if (parts.isEmpty) return null;

    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'roles': roles.map((r) => r.backendValue).toList(),
    'isActive': isActive,
    'phoneNumber': phoneNumber,
    'dob': dob,
    'cityProvince': cityProvince,
    'ward': ward,
    'detailedAddress': detailedAddress,
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
    String? dob,
    String? cityProvince,
    String? ward,
    String? detailedAddress,
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
      dob: dob ?? this.dob,
      cityProvince: cityProvince ?? this.cityProvince,
      ward: ward ?? this.ward,
      detailedAddress: detailedAddress ?? this.detailedAddress,
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
    dob,
    cityProvince,
    ward,
    detailedAddress,
    caseId,
    createdAt,
    updatedAt,
  ];
}
