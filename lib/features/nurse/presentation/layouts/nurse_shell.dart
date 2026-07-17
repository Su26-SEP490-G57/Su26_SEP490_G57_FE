import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';

/// Single Scaffold cho toàn bộ nurse feature.
/// Các page con chỉ return body widget, không có Scaffold riêng.
class NurseShell extends StatelessWidget {
  const NurseShell({required this.child, super.key});

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

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

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
                iconFilled: Icons.dashboard_rounded,
                label: 'Tổng quan',
                isActive: location == AppRoutes.nurseDashboard,
                onTap: () => context.go(AppRoutes.nurseDashboard),
              ),
              _NavItem(
                icon: Icons.people_outline_rounded,
                iconFilled: Icons.people_rounded,
                label: 'Danh sách',
                isActive: location.startsWith(AppRoutes.nursePatients),
                onTap: () => context.go(AppRoutes.nursePatients),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                iconFilled: Icons.notifications_rounded,
                label: 'Cảnh báo',
                isActive: location == AppRoutes.nurseAlerts,
                onTap: () => context.go(AppRoutes.nurseAlerts),
                badge: true,
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                iconFilled: Icons.bar_chart_rounded,
                label: 'Báo cáo',
                isActive: location == AppRoutes.nurseReports,
                onTap: () => context.go(AppRoutes.nurseReports),
              ),
              _NavItem(
                icon: Icons.more_horiz_rounded,
                iconFilled: Icons.more_horiz_rounded,
                label: 'Thêm',
                isActive: _isMoreActive(location),
                onTap: () => _showMoreSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Thêm" được highlight khi đang ở các route không thuộc 4 tab chính
  bool _isMoreActive(String location) {
    return location == AppRoutes.nurseProfile ||
        location == AppRoutes.nurseMonitoring ||
        location == AppRoutes.nurseNotifications;
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreBottomSheet(
        onNavigate: (route) {
          Navigator.of(context).pop();
          context.go(route);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Thêm" bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MoreBottomSheet extends StatelessWidget {
  const _MoreBottomSheet({required this.onNavigate});

  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFC2C6D8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thêm',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF191B24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MoreItem(
            icon: Icons.assignment_outlined,
            label: 'Quy trình & Nhiệm vụ',
            subtitle: 'Theo dõi quy trình xử trí',
            onTap: () => onNavigate(AppRoutes.nurseMonitoring),
          ),
          _MoreItem(
            icon: Icons.account_circle_outlined,
            label: 'Hồ sơ cá nhân',
            subtitle: 'Thông tin tài khoản điều dưỡng',
            onTap: () => onNavigate(AppRoutes.nurseProfile),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191B24),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF424656),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF727687),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav item
// ─────────────────────────────────────────────────────────────────────────────

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
    const inactiveColor = Color(0xFF727687);

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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    isActive ? iconFilled : icon,
                    key: ValueKey(isActive),
                    color: isActive ? activeColor : inactiveColor,
                    size: 24,
                  ),
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
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
