import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/configs/flavor/flavor_config.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poms/app.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

late final FlavorConfig appFlavorConfig;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final title = message.notification?.title ?? message.data['title']?.toString();
  final body = message.notification?.body ?? message.data['body']?.toString();

  if (title != null && body != null &&
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

void main({FlavorConfig? flavorConfig}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission();
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Permission: ${settings.authorizationStatus}');
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

  if (flavorConfig != null) {
    appFlavorConfig = flavorConfig;
  } else {
    throw Exception('A FlavorConfig must be provided');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
