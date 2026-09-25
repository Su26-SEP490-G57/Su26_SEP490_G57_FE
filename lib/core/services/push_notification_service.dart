import 'package:dio/dio.dart';
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

/// Lấy FCM token, đợi APNs trên iOS tối đa 8s trước khi thử — best-effort,
/// không throw, trả null nếu không lấy được (vd Simulator không bao giờ có
/// APNs token thật — xem `registerDeviceTokenAfterLogin`, hàm này KHÔNG được
/// gọi trên đường đi của việc đăng nhập nữa để không làm chậm/kẹt login).
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

/// Đăng ký device token SAU KHI đăng nhập thành công — chạy nền (fire-and-
/// forget), không chặn UI/luồng đăng nhập. Trước đây form login `await` lấy
/// FCM token rồi mới gửi kèm trong body /auth/login; trên iOS việc chờ APNs
/// (tới 8s, có thể không bao giờ xong trên Simulator) khiến người dùng tưởng
/// đăng nhập bị treo/lỗi. Giờ đăng nhập xong ngay, token gửi riêng qua
/// `POST /firebase/devices/register` (cần Bearer token nên phải gọi sau khi
/// đã có access token) khi nào lấy được thì thôi — chưa có thì để lần mở app
/// kế tiếp tự đăng ký lại (`PushNotificationService.initialize()`).
Future<void> registerDeviceTokenAfterLogin(Dio authenticatedDio) async {
  final token = await getFcmTokenForLogin();
  if (token == null) return;

  try {
    await authenticatedDio.post(
      '/firebase/devices/register',
      data: {'fcmToken': token},
    );
  } catch (e) {
    debugPrint('Failed to register device token after login: $e');
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
