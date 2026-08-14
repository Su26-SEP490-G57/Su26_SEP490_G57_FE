import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationPayload {
  const AppNotificationPayload({
    required this.title,
    required this.body,
    this.caseId,
    this.assessmentId,
    this.totalScore,
    this.triageColor,
    this.route,
  });

  factory AppNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return AppNotificationPayload.fromMap({
      ...message.data,
      'title': message.notification?.title,
      'body': message.notification?.body,
    });
  }

  factory AppNotificationPayload.fromMap(Map<String, dynamic> data) {
    final normalized = data.map(
      (key, value) => MapEntry(key, value?.toString()),
    );

    return AppNotificationPayload(
      title: normalized['title'] ?? 'Thông báo',
      body: normalized['body'] ?? '',
      caseId: normalized['caseId'] ?? normalized['case_id'],
      assessmentId:
          int.tryParse(normalized['assessmentId'] ?? '') ??
          int.tryParse(normalized['assessment_id'] ?? ''),
      totalScore:
          int.tryParse(normalized['totalScore'] ?? '') ??
          int.tryParse(normalized['total_score'] ?? ''),
      triageColor: normalized['triageColor'] ?? normalized['triage_color'],
      route: normalized['route'],
    );
  }

  factory AppNotificationPayload.fromJsonString(String payload) {
    return AppNotificationPayload.fromMap(
      jsonDecode(payload) as Map<String, dynamic>,
    );
  }

  final String title;
  final String body;
  final String? caseId;
  final int? assessmentId;
  final int? totalScore;
  final String? triageColor;
  final String? route;

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    if (caseId != null) 'caseId': caseId,
    if (assessmentId != null) 'assessmentId': assessmentId,
    if (totalScore != null) 'totalScore': totalScore,
    if (triageColor != null) 'triageColor': triageColor,
    if (route != null) 'route': route,
  };

  String toJsonString() => jsonEncode(toMap());
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final ValueNotifier<AppNotificationPayload?> pendingNotification =
      ValueNotifier<AppNotificationPayload?>(null);

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'patient_alert_channel',
    'Patient Alerts',
    description: 'Notifications for patient alerts',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        pendingNotification.value = AppNotificationPayload.fromJsonString(
          payload,
        );
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    AppNotificationPayload? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      payload: payload?.toJsonString(),
    );
  }

  void queueNotificationTap(AppNotificationPayload payload) {
    pendingNotification.value = payload;
  }

  AppNotificationPayload? consumePendingNotification() {
    final payload = pendingNotification.value;
    pendingNotification.value = null;
    return payload;
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  NotificationService.instance.pendingNotification.value =
      AppNotificationPayload.fromJsonString(payload);
}
