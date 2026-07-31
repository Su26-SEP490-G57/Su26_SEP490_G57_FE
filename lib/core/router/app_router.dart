import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/pages/login_page.dart';
import 'package:poms/features/auth/presentation/pages/splash_page.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/layouts/nurse_shell.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_alerts_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_dashboard_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_patient_detail_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_patients_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_priority_patients_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_profile_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_reports_page.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_tasks_page.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/presentation/layouts/patient_shell.dart';
import 'package:poms/features/patient/presentation/pages/patient_assessment_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_assessment_result_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_dashboard_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_diet_guidance_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_notifications_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_profile_page.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/constants/app_routes.dart';

// GoRouter được tạo 1 lần duy nhất, dùng refreshListenable để trigger redirect
// khi auth state thay đổi — tránh recreate router mỗi lần emit.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier();
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, _) {
    refreshNotifier.notify();
  });

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      if (isLoading) return isSplash ? null : AppRoutes.splash;

      if (!isAuthenticated) return isLogin ? null : AppRoutes.login;

      final pending = NotificationService.instance.pendingNotification.value;

      if (pending != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = rootNavigatorKey.currentContext;
          if (navigator == null) return;
          NotificationService.instance.consumePendingNotification();
          if (pending.route == 'assessment') {
            navigator.go(AppRoutes.patientAssessment);
            return;
          }

          if (pending.route == 'patient_detail' && pending.caseId != null) {
            navigator.go('${AppRoutes.nursePatients}/${pending.caseId}');
          }
        });
      }

      final role = user.primaryRole;

      if (isSplash || isLogin) return _dashboardForRole(role);

      // Role guard
      if ((role == UserRole.nurse ||
              role == UserRole.headNurse ||
              role == UserRole.admin) &&
          state.matchedLocation.startsWith('/patient')) {
        return AppRoutes.nurseDashboard;
      }

      if (role == UserRole.patient &&
          state.matchedLocation.startsWith('/nurse')) {
        return AppRoutes.patientDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // ── Nurse routes ────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => NurseShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.nurseDashboard,
            builder: (context, state) => const NurseDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.nursePatients,
            builder: (context, state) => const NursePatientsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => NursePatientDetailPage(
                  patientId: state.pathParameters['id'] ?? '',
                  patient: state.extra is PatientSummary
                      ? state.extra as PatientSummary
                      : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.nursePriorityPatients,
            builder: (context, state) => const NursePriorityPatientsPage(),
          ),
          GoRoute(
            path: AppRoutes.nurseAlerts,
            builder: (context, state) => const NurseAlertsPage(),
          ),
          GoRoute(
            path: AppRoutes.nurseReports,
            builder: (context, state) => const NurseReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.nurseMonitoring,
            builder: (context, state) => const NurseTasksPage(),
          ),
          GoRoute(
            path: AppRoutes.nurseProfile,
            builder: (context, state) => const NurseProfilePage(),
          ),
        ],
      ),

      // ── Patient routes — bottom nav ─────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => PatientShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.patientDashboard,
            builder: (context, state) => const PatientDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.patientNotifications,
            builder: (context, state) => const PatientNotificationsPage(),
          ),
          GoRoute(
            path: AppRoutes.patientProfile,
            builder: (context, state) => const PatientProfilePage(),
          ),
        ],
      ),

      // ── Patient full-screen (no shell) ──────────────────────────────
      GoRoute(
        path: AppRoutes.patientAssessment,
        builder: (context, state) => const PatientAssessmentPage(),
      ),
      GoRoute(
        path: AppRoutes.patientAssessmentResult,
        builder: (context, state) => PatientAssessmentResultPage(
          result: state.extra is SurveySubmitResult
              ? state.extra as SurveySubmitResult
              : const SurveySubmitResult(
                  assessmentId: 0,
                  caseId: '',
                  totalScore: 0,
                  triageColor: TriageColor.green,
                ),
        ),
      ),
      GoRoute(
        path: AppRoutes.patientDietGuidance,
        builder: (context, state) => const PatientDietGuidancePage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Trang không tồn tại: ${state.uri}'))),
  );

  ref.onDispose(router.dispose);

  return router;
});

// ─────────────────────────────────────────────────────────────────────────────
// Listenable để GoRouter trigger redirect mà không recreate instance
// ─────────────────────────────────────────────────────────────────────────────

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

String _dashboardForRole(UserRole? role) {
  return switch (role) {
    UserRole.admin => AppRoutes.nurseDashboard,
    UserRole.headNurse => AppRoutes.nurseDashboard,
    UserRole.nurse => AppRoutes.nurseDashboard,
    UserRole.patient => AppRoutes.patientDashboard,
    null => AppRoutes.login,
  };
}
