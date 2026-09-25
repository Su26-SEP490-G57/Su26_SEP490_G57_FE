import 'package:equatable/equatable.dart';

/// Khớp `PatientNotificationResponseDto` bên BE (GET /notifications/mine).
class PatientNotificationModel extends Equatable {
  const PatientNotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.route,
  });

  factory PatientNotificationModel.fromJson(Map<String, dynamic> json) {
    return PatientNotificationModel(
      notificationId: json['notificationId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      route: json['route'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int notificationId;
  final String title;
  final String body;

  /// 'medical' | 'system' — khớp 2 tab lọc trên màn Thông báo.
  final String category;
  final String? route;
  final bool isRead;
  final DateTime createdAt;

  PatientNotificationModel copyWith({bool? isRead}) {
    return PatientNotificationModel(
      notificationId: notificationId,
      title: title,
      body: body,
      category: category,
      route: route,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    notificationId,
    title,
    body,
    category,
    route,
    isRead,
    createdAt,
  ];
}
