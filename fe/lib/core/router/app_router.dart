import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/nurse/domain/models/patient_summary.dart';
import '../../features/nurse/presentation/layouts/nurse_shell.dart';
import '../../features/nurse/presentation/pages/nurse_alerts_page.dart';
import '../../features/nurse/presentation/pages/nurse_dashboard_page.dart';
import '../../features/nurse/presentation/pages/nurse_patient_detail_page.dart';
import '../../features/nurse/presentation/pages/nurse_patients_page.dart';
import '../../features/nurse/presentation/pages/nurse_profile_page.dart';
import '../../features/nurse/presentation/pages/nurse_reports_page.dart';
import '../../features/nurse/presentation/pages/nurse_tasks_page.dart';
import '../../features/patient/presentation/layouts/patient_shell.dart';
import '../../features/patient/presentation/pages/patient_assessment_page.dart';
import '../../features/patient/presentation/pages/patient_assessment_result_page.dart';
import '../../features/patient/presentation/pages/patient_dashboard_page.dart';
import '../../features/patient/presentation/pages/patient_notifications_page.dart';
import '../../features/patient/presentation/pages/patient_profile_page.dart';
import '../constants/app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      if (isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (!isAuthenticated) {
        return isLogin ? null : AppRoutes.login;
      }

      final role = user.primaryRole;

      if (isSplash || isLogin) {
        return _dashboardForRole(role);
      }

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
      GoRoute(
        path: AppRoutes.patientAssessmentResult,
        builder: (context, state) => PatientAssessmentResultPage(
          totalScore: state.extra is int ? state.extra as int : 0,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

String _dashboardForRole(UserRole? role) {
  return switch (role) {
    UserRole.admin => AppRoutes.nurseDashboard,
    UserRole.headNurse => AppRoutes.nurseDashboard,
    UserRole.nurse => AppRoutes.nurseDashboard,
    UserRole.patient => AppRoutes.patientDashboard,
    null => AppRoutes.login,
  };
}