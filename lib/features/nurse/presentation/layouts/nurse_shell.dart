import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/nurse/presentation/providers/alert_provider.dart';

/// Single Scaffold cho toàn bộ nurse feature.
/// Bottom nav sử dụng hiệu ứng Liquid Glass / Glassmorphism.
///
/// `extendBody: true` cho phép body vẽ xuyên qua nav bar (hiệu ứng kính).
/// Để các trang con không bị nội dung cuối khuất sau nav bar, ta override
/// `MediaQuery.padding.bottom` để inject đúng chiều cao floating nav bar.
class NurseShell extends StatelessWidget {
  const NurseShell({required this.child, super.key});

  final Widget child;

  /// Chiều cao hiệu dụng của floating nav bar tính từ safe-area bottom:
  ///   66px (container height) + 12px (khoảng cách dưới khi không có safe area)
  static const double _navBarInset = 66.0 + 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      extendBody: true,
      body: Builder(
        builder: (ctx) {
          final mq = MediaQuery.of(ctx);
          // Cộng thêm chiều cao nav bar vào padding.bottom hiện có.
          // Như vậy tất cả ListView / CustomScrollView / SafeArea trong trang con
          // đều tự động có đủ khoảng trống phía dưới — không cần sửa từng trang.
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
      bottomNavigationBar: const _GlassBottomNav(),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Glass Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _GlassBottomNav extends ConsumerWidget {
  const _GlassBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final pendingAlerts = ref.watch(pendingAlertsProvider);
    final hasPendingAlerts = pendingAlerts.isNotEmpty;

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
              // Nền kính: gradient trắng trong suốt tạo hiệu ứng frosted glass
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              // Viền highlight trắng tạo cảm giác kính có độ dày
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.0,
              ),
              // Shadow bên dưới để thanh "nổi"
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
                  icon: Icons.dashboard_outlined,
                  iconFilled: Icons.dashboard_rounded,
                  label: 'Tổng quan',
                  isActive: location == AppRoutes.nurseDashboard,
                  onTap: () => context.go(AppRoutes.nurseDashboard),
                ),
                _GlassNavItem(
                  icon: Icons.notifications_outlined,
                  iconFilled: Icons.notifications_rounded,
                  label: 'Cảnh báo',
                  isActive: location == AppRoutes.nurseAlerts,
                  onTap: () => context.go(AppRoutes.nurseAlerts),
                  badge: hasPendingAlerts,
                ),
                _GlassNavItem(
                  icon: Icons.people_outline_rounded,
                  iconFilled: Icons.people_rounded,
                  label: 'Danh sách',
                  isActive: location.startsWith(AppRoutes.nursePatients),
                  onTap: () => context.go(AppRoutes.nursePatients),
                ),
                _GlassNavItem(
                  icon: Icons.account_circle_outlined,
                  iconFilled: Icons.account_circle_rounded,
                  label: 'Hồ sơ',
                  isActive: location == AppRoutes.nurseProfile,
                  onTap: () => context.go(AppRoutes.nurseProfile),
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
    this.badge = false,
  });

  final IconData icon;
  final IconData iconFilled;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool badge;

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
            // ── Active Pill Container + Icon + Badge ─────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Active Capsule Pill Background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 48 : 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _activePrimary
                        : Colors.transparent,
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

                // Animated Icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1.0)
                          .animate(animation),
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

                // Badge Notification Red Dot
                if (badge)
                  Positioned(
                    top: isActive ? -1 : -2,
                    right: isActive ? 4 : 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA1A1A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 2.5),

            // ── Label ──────────────────────────────────────────────
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
