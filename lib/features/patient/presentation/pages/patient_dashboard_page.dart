import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/core/utils/extensions.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';
import 'package:poms/features/patient/presentation/widgets/locked_pod_banner.dart';

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
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).padding.bottom + 32,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                _PatientInfoCard(),
                SizedBox(height: 28),
                _ActionGrid(),
                SizedBox(height: 16),
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
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Avatar mascot with gradient border
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$displayName!',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Notification shortcut
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'Thông báo hệ thống',
            onPressed: () => context.push(AppRoutes.patientNotifications),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _PatientInfoCard extends ConsumerWidget {
  const _PatientInfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final currentPodAsync = ref.watch(currentPodProvider);

    return currentPodAsync.when(
      data: (pod) {
        final podNum = pod?.currentPod;
        final isLocked = pod?.isLocked ?? false;
        final podText = podNum != null ? 'POD $podNum' : 'Chưa bắt đầu';

        final startDateStr = user?.createdAt != null
            ? '${user!.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}'
            : '---';

        return Column(
          children: [
            if (pod != null && pod.isLocked) LockedPodBanner(currentPod: pod),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEDEDF9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: Title & POD Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin phục hồi',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLocked
                                ? const Color(0xFFFFEDD5)
                                : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLocked
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLocked ? '$podText (Tạm dừng)' : podText,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isLocked
                                    ? const Color(0xFFC2410C)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metrics Grid (2 Chips Side-by-Side)
                  Row(
                    children: [
                      // Patient Case ID Chip
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 15,
                                    color: Color(0xFF0284C7),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mã bệnh nhân',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user?.caseId ?? '---',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Start Date Chip
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ngày phẫu thuật',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                startDateStr,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom Guidance Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLocked
                              ? Icons.warning_amber_rounded
                              : Icons.auto_awesome_rounded,
                          color: isLocked
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF8B5CF6),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isLocked
                                ? 'Tiến trình tạm dừng - Thực hiện theo dặn dò y tế.'
                                : 'Hôm nay là một ngày tuyệt vời để hồi phục!',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? const Color(0xFFC2410C)
                                  : const Color(0xFF6D28D9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Cards Section
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
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thực hiện đầy đủ để đạt kết quả phục hồi tốt nhất',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Action Card 1: Hướng dẫn ăn hôm nay
        _BentoActionCard(
          categoryTag: 'DINH DƯỠNG',
          tagBgColor: const Color(0xFFFEF3C7),
          tagTextColor: const Color(0xFFB45309),
          gradientColors: const [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
          borderColor: const Color(0xFFFDE68A),
          iconColor: const Color(0xFFF59E0B),
          icon: Icons.restaurant_rounded,
          title: 'Hướng dẫn ăn hôm nay',
          subtitle: 'Chế độ ăn phù hợp cho tiến trình POD hiện tại',
          actionText: 'Xem hướng dẫn',
          onTap: () => context.push(AppRoutes.patientDietGuidance),
        ),
        const SizedBox(height: 14),

        // Action Card 2: Trả lời các câu hỏi
        _BentoActionCard(
          categoryTag: 'THEO DÕI HÀNG NGÀY',
          tagBgColor: const Color(0xFFD1FAE5),
          tagTextColor: const Color(0xFF047857),
          gradientColors: const [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
          borderColor: const Color(0xFFA7F3D0),
          iconColor: const Color(0xFF10B981),
          icon: Icons.assignment_turned_in_rounded,
          title: 'Trả lời các câu hỏi',
          subtitle: 'Khảo sát triệu chứng & thể trạng sức khỏe mỗi ngày',
          actionText: 'Thực hiện ngay',
          onTap: () => context.push(AppRoutes.patientAssessment),
        ),
        const SizedBox(height: 14),

        // Action Card 3: Giáo dục sức khỏe
        _BentoActionCard(
          categoryTag: 'KIẾN THỨC ERAS',
          tagBgColor: const Color(0xFFEDE9FE),
          tagTextColor: const Color(0xFF6D28D9),
          gradientColors: const [Color(0xFFF5F3FF), Color(0xFFFAF5FF)],
          borderColor: const Color(0xFFDDD6FE),
          iconColor: const Color(0xFF8B5CF6),
          icon: Icons.menu_book_rounded,
          title: 'Giáo dục sức khỏe',
          subtitle: 'Hướng dẫn hồi phục chuẩn y tế từ POD0 đến POD7',
          actionText: 'Đọc ngay',
          onTap: () => context.push(AppRoutes.patientEducation),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Bento Action Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _BentoActionCard extends StatefulWidget {
  const _BentoActionCard({
    required this.categoryTag,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.gradientColors,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onTap,
  });

  final String categoryTag;
  final Color tagBgColor;
  final Color tagTextColor;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onTap;

  @override
  State<_BentoActionCard> createState() => _BentoActionCardState();
}

class _BentoActionCardState extends State<_BentoActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Category Badge Tag & Glowing Icon Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.tagBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.categoryTag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.tagTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Icon badge container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle / Description
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Action Footer Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.actionText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
