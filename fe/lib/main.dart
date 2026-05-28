import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  // Remember Me check:
  // Nếu user không tick "Ghi nhớ đăng nhập" ở lần login trước
  // → signOut ngay khi app khởi động lại
  final rememberMe = prefs.getBool(AppConstants.keyRememberMe) ?? false;
  if (!rememberMe && FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
    await prefs.remove(AppConstants.keyUserRole);
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
