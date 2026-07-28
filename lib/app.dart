import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/core/constants/app_strings.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/core/router/app_router.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/theme/app_theme.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.pendingNotification.addListener(
      _handlePendingNotification,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingNotification();
    });
  }

  @override
  void dispose() {
    NotificationService.instance.pendingNotification.removeListener(
      _handlePendingNotification,
    );
    super.dispose();
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
