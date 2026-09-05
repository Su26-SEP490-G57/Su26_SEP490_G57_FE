import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_routes.dart';

/// Scaffold for the doctor feature — mirrors the Nurse glass nav bar design.
class DoctorShell extends StatelessWidget {
  const DoctorShell({required this.child, super.key});

  final Widget child;

  /// Height of the floating glass nav bar (same as NurseShell).
  static const double _navBarInset = 66.0 + 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      extendBody: true,
      body: Builder(
        builder: (ctx) {
          final mq = MediaQuery.of(ctx);
          return MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: mq.padding.bottom + _navBarInset,
              ),
            ),
            child: child,
          );
        },
      ),
      bottomNavigationBar: const _DoctorGlassBottomNav(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorGlassBottomNav extends StatelessWidget {
  const _DoctorGlassBottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00459A).withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DoctorNavItem(
                  icon: Icons.dashboard_outlined,
                  iconFilled: Icons.dashboard_rounded,
                  label: 'Tổng quan',
                  isActive: location == AppRoutes.doctorDashboard,
                  onTap: () => context.go(AppRoutes.doctorDashboard),
                ),
                _DoctorNavItem(
                  icon: Icons.people_outline_rounded,
                  iconFilled: Icons.people_rounded,
                  label: 'Bệnh nhân',
                  isActive: location.startsWith(AppRoutes.doctorPatients),
                  onTap: () => context.go(AppRoutes.doctorPatients),
                ),
                _DoctorNavItem(
                  icon: Icons.account_circle_outlined,
                  iconFilled: Icons.account_circle_rounded,
                  label: 'Hồ sơ',
                  isActive: location == AppRoutes.doctorProfile,
                  onTap: () => context.go(AppRoutes.doctorProfile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Nav Item (mirrors _GlassNavItem from NurseShell)
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorNavItem extends StatelessWidget {
  const _DoctorNavItem({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconFilled;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const _activeIconColor = Colors.white;
  static const _inactiveColor = Color(0xFF424656);
  static const _activePrimary = Color(0xFF00459A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        height: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 48 : 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? _activePrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isActive
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.40),
                            width: 1.0,
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _activePrimary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1.0).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    isActive ? iconFilled : icon,
                    key: ValueKey(isActive),
                    color: isActive ? _activeIconColor : _inactiveColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
                color: isActive
                    ? _activePrimary
                    : _inactiveColor.withValues(alpha: 0.75),
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.clip),
            ),
          ],
        ),
      ),
    );
  }
}
