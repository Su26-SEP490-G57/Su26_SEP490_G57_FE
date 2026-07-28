import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/configs/flavor/current_firebase_options.dart';
import 'package:poms/configs/flavor/flavor_config.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poms/app.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

late final FlavorConfig appFlavorConfig;

void main({FlavorConfig? flavorConfig}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: currentFirebaseOptions);
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  await PushNotificationService.instance.initialize();

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
