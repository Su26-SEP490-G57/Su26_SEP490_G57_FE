import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:poms/configs/flavor/current_firebase_options.dart';
import 'package:poms/configs/flavor/dev_flavor_config.dart';
import 'package:poms/configs/flavor/flavor_config.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poms/app.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

late final FlavorConfig appFlavorConfig;
late final PackageInfo appPackageInfo;

void main({FlavorConfig? flavorConfig}) {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      appFlavorConfig = flavorConfig ?? DevFlavorConfig();

      await Firebase.initializeApp(options: currentFirebaseOptions);

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        appFlavorConfig.enableCrashReporting,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Replace Flutter's default grey/red "Exception caught" box with a
      // localized fallback for a failing widget's build() — only in release
      // builds, so debug runs keep the detailed error screen for developers.
      // Reporting is unaffected: FlutterError.onError above already fires
      // from the same catch, before this builder is used to pick the
      // replacement widget.
      if (kReleaseMode) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return const Material(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Đã xảy ra lỗi. Vui lòng thử lại.'),
              ),
            ),
          );
        };
      }

      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermissions();
      await PushNotificationService.instance.initialize();

      appPackageInfo = await PackageInfo.fromPlatform();

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
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}
