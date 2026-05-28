import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/nurse/presentation/layouts/nurse_shell.dart';
import '../../features/nurse/presentation/pages/nurse_alerts_page.dart';
import '../../features/nurse/presentation/pages/nurse_dashboard_page.dart';
import '../../features/nurse/presentation/pages/nurse_patients_page.dart';
import '../../features/nurse/presentation/pages/nurse_profile_page.dart';
import '../../features/nurse/presentation/pages/nurse_tasks_page.dart';
import '../../features/patient/presentation/pages/patient_dashboard_page.dart';
import '../constants/app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.valueOrNull != null;
      final user = authState.valueOrNull;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      if (isLoading) return isSplash ? null : AppRoutes.splash;

      if (!isAuthenticated) {
        return isLogin ? null : AppRoutes.login;
      }

      if (isSplash || isLogin) {
        return _dashboardForRole(user?.role);
      }

      // Role guard
      if (user?.role == UserRole.nurse &&
          state.matchedLocation.startsWith('/patient')) {
        return AppRoutes.nurseDashboard;
      }
      if (user?.role == UserRole.patient &&
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

      // ── Nurse routes — wrapped in ShellRoute for shared bottom nav ──
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
          ),
          GoRoute(
            path: AppRoutes.nurseAlerts,
            builder: (context, state) => const NurseAlertsPage(),
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

      // ── Patient routes ──
      GoRoute(
        path: AppRoutes.patientDashboard,
        builder: (context, state) => const PatientDashboardPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});

String _dashboardForRole(UserRole? role) {
  return switch (role) {
    UserRole.nurse => AppRoutes.nurseDashboard,
    UserRole.patient => AppRoutes.patientDashboard,
    null => AppRoutes.login,
  };
}
