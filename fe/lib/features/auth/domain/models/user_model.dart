import 'package:equatable/equatable.dart';

enum UserRole { nurse, patient }

extension UserRoleX on UserRole {
  String get displayName => switch (this) {
    UserRole.nurse => 'Điều dưỡng',
    UserRole.patient => 'Bệnh nhân',
  };

  bool get isNurse => this == UserRole.nurse;
  bool get isPatient => this == UserRole.patient;

  static UserRole fromString(String value) {
    return switch (value.toLowerCase()) {
      'nurse' => UserRole.nurse,
      'patient' => UserRole.patient,
      _ => throw ArgumentError('Unknown role: $value'),
    };
  }
}

class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? displayName;
  final String? photoUrl;

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? displayName,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [uid, email, role, displayName, photoUrl];
}
