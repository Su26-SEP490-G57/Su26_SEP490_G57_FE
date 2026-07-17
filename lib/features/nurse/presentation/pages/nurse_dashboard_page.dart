import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/core/utils/extensions.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/priority_patients_provider.dart';

class NurseDashboardPage extends ConsumerStatefulWidget {
  const NurseDashboardPage({super.key});

  @override
  ConsumerState<NurseDashboardPage> createState() => _NurseDashboardPageState();
}

class _NurseDashboardPageState extends ConsumerState<NurseDashboardPage> {
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
    final displayName = user?.displayName ?? 'Điều dưỡng';

    return Column(
      children: [
        _TopAppBar(displayName: displayName),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date row ──────────────────────────────────────────
                const _DateRow(),
                const SizedBox(height: 24),

                // ── Tổng quan toàn khoa ───────────────────────────────
                const _SectionLabel(label: 'TỔNG QUAN TOÀN KHOA'),
                const SizedBox(height: 10),
                const _WardOverviewGrid(),
                const SizedBox(height: 24),

                // ── Nhóm cần ưu tiên ─────────────────────────────────
                _SectionHeader(
                  label: 'NHÓM CẦN ƯU TIÊN',
                  onViewAll: () =>
                      context.push(AppRoutes.nursePriorityPatients),
                ),
                const SizedBox(height: 10),
                const _PriorityPatientList(),
                const SizedBox(height: 24),

                // ── Alert chưa xử lý ──────────────────────────────────
                _SectionHeader(
                  label: 'ALERT CHƯA XỬ LÝ',
                  onViewAll: () => context.go(AppRoutes.nurseAlerts),
                ),
                const SizedBox(height: 10),
                const _AlertSummaryRow(),
                const SizedBox(height: 24),

                // ── Phân bố theo phòng ────────────────────────────────
                _SectionHeader(
                  label: 'PHÂN BỐ THEO PHÒNG',
                  viewAllLabel: 'Xem chi tiết',
                  onViewAll: () {},
                ),
                const SizedBox(height: 10),
                const _RoomDistributionCard(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar — primary blue, fixed
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Avatar + name
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: AppColors.primaryContainer,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ĐD. $displayName',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'ĐIỀU DƯỠNG TRƯỞNG',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFFB3C5FF),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // POMS title
              const Text(
                'POMS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 16),
              // Notification bell
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date row
// ─────────────────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final weekday = weekdays[now.weekday - 1];
    final dateStr =
        '$weekday, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF424656),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF424656),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.onViewAll,
    this.viewAllLabel = 'Xem tất cả',
  });
  final String label;
  final String viewAllLabel;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF424656),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            viewAllLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ward overview — 4-column grid
// ─────────────────────────────────────────────────────────────────────────────

class _WardOverviewGrid extends StatelessWidget {
  const _WardOverviewGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _WardStatCard(
            label: 'TỔNG BN',
            value: '24',
            valueColor: AppColors.primary,
            leftBorderColor: Colors.transparent,
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _WardStatCard(
            label: 'GREEN',
            labelColor: Color(0xFF2E7D32),
            value: '15',
            sub: '(62.5%)',
            leftBorderColor: Color(0xFF4CAF50),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _WardStatCard(
            label: 'YELLOW',
            labelColor: Color(0xFFF57F17),
            value: '6',
            sub: '(25.0%)',
            leftBorderColor: Color(0xFFFFC107),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _WardStatCard(
            label: 'RED',
            labelColor: AppColors.error,
            value: '3',
            sub: '(12.5%)',
            leftBorderColor: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _WardStatCard extends StatelessWidget {
  const _WardStatCard({
    required this.label,
    required this.value,
    required this.leftBorderColor,
    this.labelColor = const Color(0xFF424656),
    this.valueColor = const Color(0xFF191B24),
    this.sub,
  });

  final String label;
  final Color labelColor;
  final String value;
  final Color valueColor;
  final Color leftBorderColor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (leftBorderColor != Colors.transparent)
              Container(width: 4, color: leftBorderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Color(0xFF424656),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Priority patient list
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityPatientList extends ConsumerWidget {
  const _PriorityPatientList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the priorityPatientsProvider which already fetches RED and YELLOW
    final patientsAsync = ref.watch(priorityPatientsProvider);

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Không có bệnh nhân ưu tiên nào.',
                style: TextStyle(color: Color(0xFF727687)),
              ),
            ),
          );
        }

        final top3 = patients.take(3).toList();

        return Column(
          children: top3.asMap().entries.map((entry) {
            final p = entry.value;
            final isLast = entry.key == top3.length - 1;

            // Map PatientStatus from summary to the local _PatientStatus if needed,
            // or just use PatientSummary fields directly.
            // Since _PriorityPatientCard is local, we pass values directly.
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: GestureDetector(
                onTap: () => context.push(
                  AppRoutes.nursePatientDetailPath(p.code),
                  extra: p,
                ),
                child: _PriorityPatientCard(
                  code: p.code,
                  name: p.name,
                  status: p
                      .status, // We need to update _PriorityPatientCard to use PatientStatus
                  pod: p.pod,
                  room: p.room,
                  symptom:
                      'Cần chú ý', // Symptom is not provided by the summary API currently
                  dimmed: false,
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
    );
  }
}

class _PriorityPatientCard extends StatelessWidget {
  const _PriorityPatientCard({
    required this.code,
    required this.name,
    required this.status,
    required this.pod,
    required this.room,
    required this.symptom,
    required this.dimmed,
  });

  final String code;
  final String name;
  final PatientStatus status;
  final String pod;
  final String room;
  final String symptom;
  final bool dimmed;

  Color get _statusColor => status.badgeText;
  Color get _statusBg => status.badgeBg;
  String get _statusLabel => status.label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.75 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFECEDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(
                            label: _statusLabel,
                            color: _statusColor,
                            bg: _statusBg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$code - $name',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191B24),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        pod,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF424656),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF424656),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    symptom,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC2C6D8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert summary — 2 cards
// ─────────────────────────────────────────────────────────────────────────────

class _AlertSummaryRow extends StatelessWidget {
  const _AlertSummaryRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _AlertSummaryCard(
            icon: Icons.notifications_active_rounded,
            iconColor: AppColors.error,
            iconBg: AppColors.errorContainer,
            count: '2',
            countColor: AppColors.error,
            label: 'CẦN XỬ LÝ',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _AlertSummaryCard(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            iconBg: Color(0x1A0050CB),
            count: '1',
            countColor: AppColors.primary,
            label: 'ĐANG XỬ LÝ',
          ),
        ),
      ],
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  const _AlertSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.count,
    required this.countColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String count;
  final Color countColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: countColor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room distribution — donut chart + legend
// ─────────────────────────────────────────────────────────────────────────────

class _RoomDistributionCard extends StatelessWidget {
  const _RoomDistributionCard();

  static const _rooms = [
    _RoomData('Phòng 301', 4, Color(0xFF0050CB)),
    _RoomData('Phòng 302', 5, Color(0xFF006A61)),
    _RoomData('Phòng 303', 6, Color(0xFFFFC107)),
    _RoomData('Phòng 304', 4, Color(0xFFBA1A1A)),
    _RoomData('Phòng 305', 5, Color(0xFFA33200)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Donut chart
          const SizedBox(
            width: 120,
            height: 120,
            child: _DonutChart(rooms: _rooms, total: 24),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            child: Column(
              children: _rooms
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: r.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF424656),
                              ),
                            ),
                          ),
                          Text(
                            '${r.count}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF191B24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomData {
  const _RoomData(this.name, this.count, this.color);
  final String name;
  final int count;
  final Color color;
}

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.rooms, required this.total});
  final List<_RoomData> rooms;
  final int total;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => CustomPaint(
        painter: _DonutPainter(
          rooms: widget.rooms,
          total: widget.total,
          progress: _anim.value,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.total}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191B24),
                ),
              ),
              const Text(
                'BỆNH NHÂN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.rooms,
    required this.total,
    required this.progress,
  });

  final List<_RoomData> rooms;
  final int total;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFECEDFA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, trackPaint);

    // Segments
    double startAngle = -math.pi / 2;
    for (final room in rooms) {
      final sweep = (room.count / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = room.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += (room.count / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}
