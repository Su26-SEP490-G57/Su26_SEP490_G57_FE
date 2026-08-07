import 'package:flutter/foundation.dart';
import 'package:poms/main.dart';

// Debug builds only (assert), and dev flavor only (see enableDebugLogging).
void debugLog(String message) {
  assert(() {
    if (appFlavorConfig.enableDebugLogging) {
      debugPrint(message);
    }
    return true;
  }());
}
