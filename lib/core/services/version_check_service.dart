import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:poms/main.dart';

class VersionCheckResult {
  const VersionCheckResult({
    required this.versionName,
    required this.isMandatory,
    required this.downloadUrl,
    this.releaseNotes,
  });

  final String versionName;
  final bool isMandatory;
  final String downloadUrl;
  final String? releaseNotes;
}

class VersionCheckService {
  VersionCheckService._();
  static final instance = VersionCheckService._();

  /// Set by the 426 interceptor in dio_client.dart; app.dart listens via
  /// addListener, same pattern as NotificationService.instance.pendingNotification.
  final ValueNotifier<VersionCheckResult?> forcedUpdate = ValueNotifier(null);
  bool _handlingForcedUpdate = false;

  /// Called from the onError interceptor when any request comes back 426.
  /// Treats the 426 itself as ground truth for "mandatory" — does not defer to
  /// whatever version.json's own forceUpdate/minSupportedVersionCode say, since
  /// the BE's and FE's copies of MIN_SUPPORTED_VERSION_CODE are deliberately
  /// decoupled and can disagree. Only calls check() to enrich the dialog with a
  /// real downloadUrl/versionName when available.
  Future<void> reportForcedUpdate({String? message}) async {
    if (_handlingForcedUpdate) return; // dedupe a burst of concurrent 426s
    _handlingForcedUpdate = true;
    try {
      final fetched = await check();
      forcedUpdate.value = VersionCheckResult(
        versionName: fetched?.versionName ?? '',
        isMandatory: true,
        downloadUrl: fetched?.downloadUrl ?? '',
        releaseNotes: fetched?.releaseNotes ?? message,
      );
    } finally {
      _handlingForcedUpdate = false;
    }
  }

  Future<VersionCheckResult?> check() async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await dio.get(
        '${appFlavorConfig.apiBaseUrl}/version.json',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['schemaVersion'] != 1) return null; // unrecognized shape, skip

      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final platform = data[platformKey] as Map<String, dynamic>?;
      if (platform == null) return null;

      final serverVersionCode = platform['versionCode'] as int;
      final installedVersionCode = int.parse(appPackageInfo.buildNumber);
      if (installedVersionCode >= serverVersionCode) return null; // up to date

      final forceUpdate = platform['forceUpdate'] as bool? ?? false;
      final minSupported = platform['minSupportedVersionCode'] as int?;
      final isMandatory =
          forceUpdate ||
          (minSupported != null && installedVersionCode < minSupported);

      return VersionCheckResult(
        versionName: platform['versionName'] as String,
        isMandatory: isMandatory,
        downloadUrl: platform['downloadUrl'] as String,
        releaseNotes: platform['releaseNotes'] as String?,
      );
    } catch (_) {
      return null; // offline / 404 / malformed — never block app usage over this
    }
  }
}
