import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:poms/core/constants/app_strings.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/core/router/app_router.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/services/version_check_service.dart';
import 'package:poms/core/theme/app_theme.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _updateDialogShowing = false;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.pendingNotification.addListener(
      _handlePendingNotification,
    );
    VersionCheckService.instance.forcedUpdate.addListener(_handleForcedUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingNotification();
      _checkAppVersion();
    });
  }

  @override
  void dispose() {
    NotificationService.instance.pendingNotification.removeListener(
      _handlePendingNotification,
    );
    VersionCheckService.instance.forcedUpdate.removeListener(
      _handleForcedUpdate,
    );
    super.dispose();
  }

  Future<void> _checkAppVersion() async {
    final result = await VersionCheckService.instance.check();
    if (result == null || !mounted) return;
    _showUpdateDialog(result);
  }

  void _handleForcedUpdate() {
    final result = VersionCheckService.instance.forcedUpdate.value;
    if (result == null || !mounted) return;
    _showUpdateDialog(result);
  }

  void _showUpdateDialog(VersionCheckResult result) {
    // Dedupe: a proactive check and a live 426 could both fire close together,
    // and PopScope(canPop: false) means a mandatory dialog never naturally
    // closes until the app is updated — don't stack a second one on top of it.
    if (_updateDialogShowing) return;

    // _AppState.context sits above MaterialApp.router (App.build() returns
    // it), so it has no Navigator ancestor of its own — Navigator.of(context)
    // would throw. rootNavigatorKey.currentContext is attached to the
    // Navigator GoRouter builds inside MaterialApp.router, so it actually
    // resolves. Can be null very early before the first frame; skip rather
    // than crash if so.
    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) return;

    _updateDialogShowing = true;
    showDialog(
      context: dialogContext,
      barrierDismissible: !result.isMandatory,
      builder: (ctx) => PopScope(
        canPop: !result.isMandatory,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            result.isMandatory
                ? AppStrings.updateRequiredTitle
                : AppStrings.updateAvailableTitle,
          ),
          content: Text(
            [
              AppStrings.updateAvailableMessage(result.versionName),
              if (result.releaseNotes != null) result.releaseNotes!,
            ].join('\n\n'),
          ),
          actions: [
            if (!result.isMandatory)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(AppStrings.updateLater),
              ),
            if (result.downloadUrl.isNotEmpty)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(result.downloadUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(AppStrings.updateNow),
              ),
          ],
        ),
      ),
    ).then((_) => _updateDialogShowing = false);
  }

  void _handlePendingNotification() {
    final router = ref.read(routerProvider);
    final authState = ref.read(authStateProvider);

    // Chưa đăng nhập thì không xử lý.
    // Giữ nguyên pending notification để sau khi login sẽ xử lý tiếp.
    if (authState.isLoading || authState.valueOrNull == null) {
      return;
    }

    final payload = NotificationService.instance.consumePendingNotification();

    if (payload == null) return;

    final role = authState.valueOrNull!.primaryRole;

    // ===== Patient =====
    if (role == UserRole.patient) {
      router.go(AppRoutes.patientAssessment);
      return;
    }

    // ===== Nurse / Head Nurse / Admin =====
    if ((role == UserRole.nurse ||
            role == UserRole.headNurse ||
            role == UserRole.admin) &&
        payload.caseId != null &&
        payload.caseId!.isNotEmpty) {
      router.go(AppRoutes.nursePatientDetailPath(payload.caseId!));
      return;
    }

    // fallback
    if (role == UserRole.patient) {
      router.go(AppRoutes.patientDashboard);
    } else {
      router.go(AppRoutes.nurseDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
