import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:poms/configs/flavor/current_firebase_options.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/utils/debug_log.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: currentFirebaseOptions);

  final title =
      message.notification?.title ?? message.data['title']?.toString();
  final body = message.notification?.body ?? message.data['body']?.toString();

  if (title != null &&
      body != null &&
      message.notification == null &&
      (message.data['title'] != null || message.data['body'] != null)) {
    await NotificationService.instance.initialize();
    await NotificationService.instance.showNotification(
      title: title,
      body: body,
      payload: AppNotificationPayload.fromRemoteMessage(message),
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  Future<void> initialize() async {
    if (kIsWeb) {
      debugLog('Push notification service skipped on web platform.');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugLog('Permission: ${settings.authorizationStatus}');
    // Never log the raw token, even gated — it's a device credential.
    await messaging.getToken();
    debugLog('FCM token acquired');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugLog('========== FCM RECEIVED ==========');
      debugLog('Title: ${message.notification?.title}');
      debugLog('Body: ${message.notification?.body}');

      await NotificationService.instance.showNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: AppNotificationPayload.fromRemoteMessage(message),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationService.instance.queueNotificationTap(
        AppNotificationPayload.fromRemoteMessage(message),
      );
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      NotificationService.instance.queueNotificationTap(
        AppNotificationPayload.fromRemoteMessage(initialMessage),
      );
    }
  }
}
