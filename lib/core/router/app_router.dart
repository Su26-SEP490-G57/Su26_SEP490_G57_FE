import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/pages/login_page.dart';
import 'package:poms/features/auth/presentation/pages/splash_page.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/doctor/presentation/layouts/doctor_shell.dart';
import 'package:poms/features/doctor/presentation/pages/doctor_alerts_page.dart';
import 'package:poms/features/doctor/presentation/pages/doctor_dashboard_page.dart';
import 'package:poms/features/doctor/presentation/pages/doctor_patient_detail_page.dart';
import 'package:poms/features/doctor/presentation/pages/doctor_patients_page.dart';
import 'package:poms/features/doctor/presentation/pages/doctor_profile_page.dart';
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
import 'package:poms/features/patient/presentation/pages/patient_assessment_history_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_assessment_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_assessment_result_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_dashboard_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_diet_guidance_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_health_education_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_notifications_page.dart';
import 'package:poms/features/patient/presentation/pages/patient_profile_page.dart';
import 'package:poms/core/services/notification_service.dart';
import 'package:poms/core/services/version_check_service.dart';
import 'package:poms/core/constants/app_routes.dart';


// Module-level (not local to routerProvider) so any code outside the routed
// widget tree — e.g. _AppState, which sits above MaterialApp.router and has
// no Navigator ancestor of its own — can reach a BuildContext that actually
// resolves via Navigator.of(), by using rootNavigatorKey.currentContext
// instead of its own context.
final rootNavigatorKey = GlobalKey<NavigatorState>();

// GoRouter được tạo 1 lần duy nhất, dùng refreshListenable để trigger redirect
// khi auth state thay đổi — tránh recreate router mỗi lần emit.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier();
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, _) {
    refreshNotifier.notify();
  });

  // Re-evaluate redirect whenever the version-check block flag changes (check
  // starts/resolves, dialog shown/dismissed) — not just on auth-state changes
  // — so redirect below can react to it immediately either direction.
  void onBlockNavigationChanged() => refreshNotifier.notify();
  VersionCheckService.instance.blockNavigation.addListener(
    onBlockNavigationChanged,
  );

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

      // Version check in flight, or an update dialog (mandatory or not) is
      // currently up — stay on/return to splash rather than let auth-based
      // redirect below (which usually resolves faster, e.g. from cached
      // "remember me" state) navigate away underneath the dialog.
      if (VersionCheckService.instance.blockNavigation.value) {
        return isSplash ? null : AppRoutes.splash;
      }

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

      // Role guard — nurse/admin/headNurse/doctor không được vào /patient
      if ((role == UserRole.nurse ||
              role == UserRole.headNurse ||
              role == UserRole.admin ||
              role == UserRole.doctor) &&
          state.matchedLocation.startsWith('/patient')) {
        return _dashboardForRole(role);
      }

      // Role guard — patient không được vào /nurse hay /doctor
      if (role == UserRole.patient &&
          (state.matchedLocation.startsWith('/nurse') ||
              state.matchedLocation.startsWith('/doctor'))) {
        return AppRoutes.patientDashboard;
      }

      // Role guard — nurse/admin/headNurse không được vào /doctor
      if ((role == UserRole.nurse ||
              role == UserRole.headNurse ||
              role == UserRole.admin) &&
          state.matchedLocation.startsWith('/doctor')) {
        return AppRoutes.nurseDashboard;
      }

      // Role guard — doctor không được vào /nurse
      if (role == UserRole.doctor &&
          state.matchedLocation.startsWith('/nurse')) {
        return AppRoutes.doctorDashboard;
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

      // ── Doctor routes — bottom nav ───────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DoctorShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.doctorDashboard,
            builder: (context, state) => const DoctorDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorAlerts,
            builder: (context, state) => const DoctorAlertsPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorPatients,
            builder: (context, state) => const DoctorPatientsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => DoctorPatientDetailPage(
                  patientId: state.pathParameters['id'] ?? '',
                  patient: state.extra is PatientSummary
                      ? state.extra as PatientSummary
                      : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.doctorProfile,
            builder: (context, state) => const DoctorProfilePage(),
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
            path: AppRoutes.patientAssessmentHistory,
            builder: (context, state) => const PatientAssessmentHistoryPage(),
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
      GoRoute(
        path: AppRoutes.patientEducation,
        builder: (context, state) => const PatientHealthEducationPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Trang không tồn tại: ${state.uri}')),
    ),
  );

  ref.onDispose(() {
    VersionCheckService.instance.blockNavigation.removeListener(
      onBlockNavigationChanged,
    );
    router.dispose();
  });

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
    UserRole.doctor => AppRoutes.doctorDashboard,
    UserRole.patient => AppRoutes.patientDashboard,
    null => AppRoutes.login,
  };
}
