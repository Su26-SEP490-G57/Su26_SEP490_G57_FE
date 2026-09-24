import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_routes.dart';

/// Shell cho toàn bộ patient feature — cung cấp Scaffold + Liquid Glass bottom nav.
/// `extendBody: true` cho phép body vẽ xuyên qua nav bar (hiệu ứng kính mờ nhìn xuyên qua).
class PatientShell extends StatelessWidget {
  const PatientShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      extendBody: true,
      body: child,
      bottomNavigationBar: const _PatientGlassBottomNav(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _PatientGlassBottomNav extends StatelessWidget {
  const _PatientGlassBottomNav();

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
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.20),
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
                _GlassNavItem(
                  icon: Icons.home_outlined,
                  iconFilled: Icons.home_rounded,
                  label: 'Trang chủ',
                  isActive: location == AppRoutes.patientDashboard,
                  onTap: () => context.go(AppRoutes.patientDashboard),
                ),
                _GlassNavItem(
                  icon: Icons.history_outlined,
                  iconFilled: Icons.history_rounded,
                  label: 'Lịch sử',
                  isActive:
                      location == AppRoutes.patientAssessmentHistory ||
                      location == AppRoutes.patientNotifications,
                  onTap: () => context.go(AppRoutes.patientAssessmentHistory),
                ),
                _GlassNavItem(
                  icon: Icons.person_outlined,
                  iconFilled: Icons.person_rounded,
                  label: 'Tài khoản',
                  isActive: location == AppRoutes.patientProfile,
                  onTap: () => context.go(AppRoutes.patientProfile),
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
// Individual Glass Nav Item
// ─────────────────────────────────────────────────────────────────────────────

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
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
        width: 80,
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
                      scale: Tween<double>(
                        begin: 0.82,
                        end: 1.0,
                      ).animate(animation),
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
