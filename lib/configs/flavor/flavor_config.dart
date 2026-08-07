abstract class FlavorConfig {
  String get appName;
  String get bundleId;

  String get apiBaseUrl;
  int get apiConnectTimeout;
  int get apiReceiveTimeout;

  // Debug-only logging (Dio request/response logging via pretty_dio_logger,
  // plus ad hoc debugLog() calls) also requires a non-release build (see the
  // assert-gates in dio_client.dart / debug_log.dart) — this flag
  // additionally scopes it to dev, since staging traffic can carry real-ish
  // patient data that shouldn't end up in adb logcat.
  bool get enableDebugLogging;

  // Whether Firebase Crashlytics collection is enabled — off for dev so
  // local iteration doesn't pollute the crash-reporting console with
  // developer-machine noise.
  bool get enableCrashReporting;
}
