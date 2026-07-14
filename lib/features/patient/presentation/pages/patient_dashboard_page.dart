import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  ConsumerState<PatientDashboardPage> createState() =>
      _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final justLoggedIn = ref.read(authNotifierProvider).justLoggedIn;
      if (justLoggedIn) {
        ref.read(authNotifierProvider.notifier).clearLoginToast();
        context.showTopToast('Đăng nhập thành công!', isSuccess: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final displayName = user?.displayName.split(' ').first ?? 'bạn';

    return Column(
      children: [
        _TopAppBar(displayName: displayName),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const _PatientInfoCard(),
                const SizedBox(height: 32),
                const _ActionGrid(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            // Avatar mascot
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
                border: Border.all(color: AppColors.primaryContainer, width: 2),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            // Greeting
            Expanded(
              child: Text(
                'Chào bạn, $displayName!',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Search button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E7F3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient info card
// ─────────────────────────────────────────────────────────────────────────────

class _PatientInfoCard extends StatelessWidget {
  const _PatientInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Thông tin rows
          const _InfoRow(
            label: 'Mã bệnh nhân',
            value: 'BN001',
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'POD hiện tại',
            value: 'POD1',
            valueColor: const Color(0xFF006E2F), // secondary
          ),
          const SizedBox(height: 16),
          const _InfoRow(
            label: 'Ngày bắt đầu phẫu thuật',
            value: '12/05/2025',
            valueColor: AppColors.onSurface,
          ),

          // Divider + info message
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Divider(height: 1, color: Color(0xFFEDEDF9)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.info_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hôm nay là một ngày tuyệt vời để hồi phục!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: AppColors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action grid — 2×2 bento style
// ─────────────────────────────────────────────────────────────────────────────

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các hoạt động hôm nay',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            _ActionCard(
              backgroundColor: const Color(0xFFFFF7E6),
              borderColor: const Color(0xFFFFE7C4),
              iconColor: const Color(0xFFF59E0B),
              icon: Icons.restaurant_rounded,
              label: 'Hướng dẫn ăn hôm nay',
              labelColor: const Color(0xFF854D0E),
              onTap: () => context.push(AppRoutes.patientDietGuidance),
            ),
            _ActionCard(
              backgroundColor: const Color(0xFFE6F9F1),
              borderColor: const Color(0xFFC6F6D5),
              iconColor: const Color(0xFF10B981),
              icon: Icons.assignment_turned_in_rounded,
              label: 'Trả lời các câu hỏi',
              labelColor: const Color(0xFF065F46),
              onTap: () => context.push(AppRoutes.patientAssessment),
            ),
            const _ActionCard(
              backgroundColor: Color(0xFFF3E8FF),
              borderColor: Color(0xFFE9D5FF),
              iconColor: Color(0xFF8B5CF6),
              icon: Icons.menu_book_rounded,
              label: 'Giáo dục sức khỏe',
              labelColor: Color(0xFF5B21B6),
            ),
            const _ActionCard(
              backgroundColor: Color(0xFFFEE2E2),
              borderColor: Color(0xFFFECACA),
              iconColor: Color(0xFFEF4444),
              icon: Icons.notifications_active_rounded,
              label: 'Lưu ý tới điều dưỡng',
              labelColor: Color(0xFF991B1B),
              pulseIcon: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.labelColor,
    this.pulseIcon = false,
    this.onTap,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final String label;
  final Color labelColor;
  final bool pulseIcon;
  final VoidCallback? onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.pulseIcon) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.pulseIcon
                    ? FadeTransition(
                        opacity: _pulseAnim,
                        child: Icon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 28,
                        ),
                      )
                    : Icon(widget.icon, color: widget.iconColor, size: 28),
              ),
              const Spacer(),
              // Label
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.labelColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
