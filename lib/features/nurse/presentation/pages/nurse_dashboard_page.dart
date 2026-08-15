import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/core/utils/extensions.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/analytics_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';

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
    final patientState = ref.watch(patientNotifierProvider);
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
                _WardOverviewGrid(patients: patientState.patients),
                const SizedBox(height: 24),

                // ── Nhóm cần ưu tiên ─────────────────────────────────
                _SectionHeader(
                  label: 'NHÓM CẦN ƯU TIÊN',
                  onViewAll: () =>
                      context.push(AppRoutes.nursePriorityPatients),
                ),
                const SizedBox(height: 10),
                _PriorityPatientList(patients: patientState.patients),
                const SizedBox(height: 24),

                // ── Tỷ lệ tuân thủ ────────────────────────────────────
                const _SectionLabel(label: 'TỶ LỆ TUÂN THỦ'),
                const SizedBox(height: 10),
                const _ComplianceOverviewCard(),
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
                    'ĐIỀU DƯỠNG',
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
  const _SectionHeader({required this.label, required this.onViewAll});
  final String label;
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
          child: const Text(
            'Xem tất cả',
            style: TextStyle(
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
  const _WardOverviewGrid({required this.patients});

  final List<PatientSummary> patients;

  @override
  Widget build(BuildContext context) {
    final total = patients.length;

    final green = patients.where((e) => e.status == PatientStatus.green).length;
    final yellow = patients
        .where((e) => e.status == PatientStatus.yellow)
        .length;
    final red = patients.where((e) => e.status == PatientStatus.red).length;

    String percent(int count) {
      if (total == 0) return '(0%)';
      return '(${(count / total * 100).toStringAsFixed(1)}%)';
    }

    return Row(
      children: [
        Expanded(
          child: _WardStatCard(
            label: 'TỔNG BN',
            value: '$total',
            valueColor: AppColors.primary,
            leftBorderColor: Colors.transparent,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WardStatCard(
            label: 'GREEN',
            labelColor: const Color(0xFF2E7D32),
            value: '$green',
            sub: percent(green),
            leftBorderColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WardStatCard(
            label: 'YELLOW',
            labelColor: const Color(0xFFF57F17),
            value: '$yellow',
            sub: percent(yellow),
            leftBorderColor: const Color(0xFFFFC107),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WardStatCard(
            label: 'RED',
            labelColor: AppColors.error,
            value: '$red',
            sub: percent(red),
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

class _PriorityPatientList extends StatelessWidget {
  const _PriorityPatientList({required this.patients});

  final List<PatientSummary> patients;
  @override
  Widget build(BuildContext context) {
    final priorityPatients = [...patients];

    priorityPatients.sort((a, b) {
      final priority = {
        PatientStatus.red: 0,
        PatientStatus.yellow: 1,
        PatientStatus.green: 2,
      };

      final compare = priority[a.status]!.compareTo(priority[b.status]!);

      if (compare != 0) {
        return compare;
      }

      return a.pod.compareTo(b.pod);
    });

    final displayPatients = priorityPatients
        .where((p) => p.status == PatientStatus.red)
        .take(3)
        .toList();

    return Column(
      children: displayPatients
          .map(
            (patient) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PriorityPatientCard(
                patient: patient,
                onTap: () => context.push(
                  AppRoutes.nursePatientDetailPath(patient.code),
                  extra: patient,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PriorityPatientCard extends StatelessWidget {
  const _PriorityPatientCard({required this.patient, required this.onTap});

  final PatientSummary patient;
  final VoidCallback onTap;

  PatientStatus get status => patient.status;
  String get code => patient.code;
  String get name => patient.name;
  String get pod {
    if (patient.pod.startsWith('POD')) {
      return patient.pod;
    }
    return 'POD ${patient.pod}';
  }

  String get room => roomLabel(patient.room);
  String get symptom {
    switch (patient.status) {
      case PatientStatus.red:
        return 'Cần theo dõi sát';
      case PatientStatus.yellow:
        return 'Cần theo dõi';
      case PatientStatus.green:
        return 'Đang hồi phục tốt';
    }
  }

  Color get _statusColor => status.badgeText;
  Color get _statusBg => status.badgeBg;
  String get _statusLabel => status.label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _StatusBadge(
                                  label: _statusLabel,
                                  color: _statusColor,
                                  bg: _statusBg,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF191B24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$room • $pod',
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
/*
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
*/
String roomLabel(String raw) {
  final match = RegExp(r'P?(\d+)').firstMatch(raw);

  if (match == null) {
    return raw;
  }

  return 'Phòng ${match.group(1)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Compliance overview — donut chart Tuân thủ / Không tuân thủ
// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceOverviewCard extends ConsumerWidget {
  const _ComplianceOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(complianceOverviewProvider);

    return Container(
      width: double.infinity,
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
      child: overview.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _ComplianceInlineMessage(
          message: 'Không thể tải dữ liệu tuân thủ',
          onRetry: () => ref.invalidate(complianceOverviewProvider),
        ),
        data: (overview) {
          if (overview.total == 0) {
            return const _ComplianceInlineMessage(
              message: 'Chưa có dữ liệu tuân thủ',
            );
          }
          final percent = (overview.complianceRate * 100).round();

          return Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: _ComplianceDonut(overview: overview, percent: percent),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _ComplianceLegendRow(
                      color: AppColors.statusNormal,
                      label: 'Tuân thủ',
                      count: overview.compliant,
                    ),
                    const SizedBox(height: 8),
                    _ComplianceLegendRow(
                      color: AppColors.error,
                      label: 'Không tuân thủ',
                      count: overview.nonCompliant,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ComplianceInlineMessage extends StatelessWidget {
  const _ComplianceInlineMessage({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF727687),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComplianceLegendRow extends StatelessWidget {
  const _ComplianceLegendRow({
    required this.color,
    required this.label,
    required this.count,
  });
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF424656),
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191B24),
          ),
        ),
      ],
    );
  }
}

class _ComplianceDonut extends StatelessWidget {
  const _ComplianceDonut({required this.overview, required this.percent});
  final ComplianceOverview overview;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ComplianceDonutPainter(overview: overview),
      child: Center(
        child: Text(
          '$percent%',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191B24),
          ),
        ),
      ),
    );
  }
}

class _ComplianceDonutPainter extends CustomPainter {
  _ComplianceDonutPainter({required this.overview});
  final ComplianceOverview overview;

  @override
  void paint(Canvas canvas, Size size) {
    final total = overview.total;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 14.0;

    final segments = [
      (overview.compliant, AppColors.statusNormal),
      (overview.nonCompliant, AppColors.error),
    ];

    var startAngle = -math.pi / 2;
    for (final (count, color) in segments) {
      if (count == 0) continue;
      final sweep = (count / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_ComplianceDonutPainter old) => old.overview != overview;
}
