import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for all platforms.
/// Generated from the Firebase Console — project: poms-25f1c
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.windows => windows,
      TargetPlatform.macOS => macos,
      TargetPlatform.linux => throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for Linux.',
      ),
      _ => throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      ),
    };
  }

  // ── Web ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYdzLJfXY_CNIHrr5AnA9f_8a7bHVcw1A',
    authDomain: 'poms-25f1c.firebaseapp.com',
    projectId: 'poms-25f1c',
    storageBucket: 'poms-25f1c.firebasestorage.app',
    messagingSenderId: '781624065817',
    appId: '1:781624065817:web:0c829f768e2407fec0cf88',
    measurementId: 'G-8JHXMRTECW',
  );

  // ── Android ──────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDc7ruu28M94z0sQvLl9D7bkeAHslPafvE',
    authDomain: 'poms-25f1c.firebaseapp.com',
    projectId: 'poms-25f1c',
    storageBucket: 'poms-25f1c.firebasestorage.app',
    messagingSenderId: '781624065817',
    appId: '1:781624065817:android:26cc6c516c6423a5c0cf88',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  // TODO: Replace with real iOS app values from Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYdzLJfXY_CNIHrr5AnA9f_8a7bHVcw1A',
    authDomain: 'poms-25f1c.firebaseapp.com',
    projectId: 'poms-25f1c',
    storageBucket: 'poms-25f1c.firebasestorage.app',
    messagingSenderId: '781624065817',
    appId: '1:781624065817:ios:placeholder',
    iosBundleId: 'android.app.poms',
  );

  // ── Windows ───────────────────────────────────────────────────────────────
  // Windows uses the web config (REST API based)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDYdzLJfXY_CNIHrr5AnA9f_8a7bHVcw1A',
    authDomain: 'poms-25f1c.firebaseapp.com',
    projectId: 'poms-25f1c',
    storageBucket: 'poms-25f1c.firebasestorage.app',
    messagingSenderId: '781624065817',
    appId: '1:781624065817:web:0c829f768e2407fec0cf88',
    measurementId: 'G-8JHXMRTECW',
  );

  // ── macOS ─────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDYdzLJfXY_CNIHrr5AnA9f_8a7bHVcw1A',
    authDomain: 'poms-25f1c.firebaseapp.com',
    projectId: 'poms-25f1c',
    storageBucket: 'poms-25f1c.firebasestorage.app',
    messagingSenderId: '781624065817',
    appId: '1:781624065817:web:0c829f768e2407fec0cf88',
    measurementId: 'G-8JHXMRTECW',
  );
}
