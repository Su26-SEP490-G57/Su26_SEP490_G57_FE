import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:poms/configs/flavor/current_firebase_options.dart';
import 'package:poms/core/services/notification_service.dart';

Future<void> _awaitApnsTokenOnIOS(
  FirebaseMessaging messaging, {
  int maxAttempts = 5,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (await messaging.getAPNSToken() != null) return;
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// Lấy FCM token để gửi kèm lúc đăng nhập. Trên iOS, ngay sau khi app vừa mở
/// APNs token có thể chưa kịp đăng ký xong — gọi `getToken()` lúc đó ném
/// `apns-token-not-set`. Đợi thêm (đăng nhập xảy ra sau initialize() ở
/// main.dart nên thường đã sẵn sàng, phòng khi chưa thì đợi thêm tối đa 8s)
/// rồi mới thử; nếu vẫn chưa có, trả về null — đăng nhập vẫn tiếp tục bình
/// thường, chỉ là thiết bị đó tạm thời chưa nhận được push cho tới lần mở
/// app kế tiếp (PushNotificationService.initialize() sẽ đăng ký lại).
Future<String?> getFcmTokenForLogin() async {
  if (kIsWeb) return null;

  final messaging = FirebaseMessaging.instance;
  await _awaitApnsTokenOnIOS(messaging, maxAttempts: 8);

  try {
    return await messaging.getToken();
  } catch (e) {
    debugPrint('Failed to get FCM token: $e');
    return null;
  }
}

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
      debugPrint('Push notification service skipped on web platform.');
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
    debugPrint('Permission: ${settings.authorizationStatus}');
    await _awaitApnsTokenOnIOS(messaging);
    final token = await messaging.getToken();
    debugPrint('FCM Token:');
    debugPrint(token);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('========== FCM RECEIVED ==========');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');

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
