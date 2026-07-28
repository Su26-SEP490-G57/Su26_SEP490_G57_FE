import 'package:firebase_core/firebase_core.dart';
import 'package:poms/configs/firebase/firebase_options_dev.dart' as dev;
import 'package:poms/configs/firebase/firebase_options_prod.dart' as prod;
import 'package:poms/configs/firebase/firebase_options_staging.dart' as staging;

const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

/// Resolves to the [FirebaseOptions] for the flavor the app was built with.
///
/// Backed by the `FLAVOR` dart-define (see build-workflow.yml / launch.json)
/// rather than `FlavorConfig`, because the FCM background-message isolate
/// is spawned directly by the OS and never re-runs `main()`, so it can only
/// rely on compile-time constants — not values passed at runtime.
FirebaseOptions get currentFirebaseOptions {
  switch (_flavor) {
    case 'staging':
      return staging.DefaultFirebaseOptions.currentPlatform;
    case 'prod':
      return prod.DefaultFirebaseOptions.currentPlatform;
    case 'dev':
    default:
      return dev.DefaultFirebaseOptions.currentPlatform;
  }
}
