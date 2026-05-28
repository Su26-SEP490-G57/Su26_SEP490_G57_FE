import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

/// Single Scaffold cho toàn bộ nurse feature.
/// Các page con chỉ return body widget, không có Scaffold riêng.
class NurseShell extends StatelessWidget {
  const NurseShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: child,
      bottomNavigationBar: const _NurseBottomNav(),
    );
  }
}

class _NurseBottomNav extends StatelessWidget {
  const _NurseBottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        border: Border(top: BorderSide(color: Color(0xFFC2C6D8), width: 1)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                iconFilled: Icons.dashboard,
                label: 'Overview',
                isActive: location == AppRoutes.nurseDashboard,
                onTap: () => context.go(AppRoutes.nurseDashboard),
              ),
              _NavItem(
                icon: Icons.person_search_outlined,
                iconFilled: Icons.person_search,
                label: 'Patients',
                isActive: location.startsWith(AppRoutes.nursePatients),
                onTap: () => context.go(AppRoutes.nursePatients),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                iconFilled: Icons.notifications,
                label: 'Alerts',
                isActive: location == AppRoutes.nurseAlerts,
                onTap: () => context.go(AppRoutes.nurseAlerts),
                badge: true,
              ),
              _NavItem(
                icon: Icons.assignment_outlined,
                iconFilled: Icons.assignment,
                label: 'Tasks',
                isActive: location == AppRoutes.nurseMonitoring,
                onTap: () => context.go(AppRoutes.nurseMonitoring),
              ),
              _NavItem(
                icon: Icons.account_circle_outlined,
                iconFilled: Icons.account_circle,
                label: 'Account',
                isActive: location == AppRoutes.nurseProfile,
                onTap: () => context.go(AppRoutes.nurseProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final IconData iconFilled;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0050CB);
    const inactiveColor = Color(0xFF424656);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? iconFilled : icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBA1A1A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
