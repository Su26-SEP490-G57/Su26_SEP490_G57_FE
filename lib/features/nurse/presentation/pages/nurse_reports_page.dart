import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/analytics_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';

enum _DetailTab { compliance, assessment }

class NurseReportsPage extends ConsumerStatefulWidget {
  const NurseReportsPage({super.key});

  @override
  ConsumerState<NurseReportsPage> createState() => _NurseReportsPageState();
}

class _NurseReportsPageState extends ConsumerState<NurseReportsPage> {
  String? _selectedCaseId;
  _DetailTab _tab = _DetailTab.compliance;

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientNotifierProvider).patients;
    final selectedCaseId = _selectedCaseId ?? patients.firstOrNull?.code;

    return Column(
      children: [
        const _TopAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(label: 'TỶ LỆ TUÂN THỦ'),
                const SizedBox(height: 10),
                const _ComplianceOverviewCard(),
                const SizedBox(height: 24),

                const _SectionLabel(label: 'DANH SÁCH NGƯỜI BỆNH'),
                const SizedBox(height: 10),
                _PatientSelectionList(
                  patients: patients,
                  selectedCaseId: selectedCaseId,
                  onSelect: (caseId) =>
                      setState(() => _selectedCaseId = caseId),
                ),
                const SizedBox(height: 24),

                if (selectedCaseId != null) ...[
                  _DetailTabSwitcher(
                    tab: _tab,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: 12),
                  switch (_tab) {
                    _DetailTab.compliance => _ComplianceStatsPanel(
                      caseId: selectedCaseId,
                    ),
                    _DetailTab.assessment => _EndOfDayAssessmentPanel(
                      caseId: selectedCaseId,
                    ),
                  },
                ] else
                  const _EmptyPanel(message: 'Chưa có người bệnh nào'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: const SizedBox(
        height: 64,
        child: Center(
          child: Text(
            'Thống kê dữ liệu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
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

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF727687),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compliance overview donut — Tuân thủ / Không tuân thủ
// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceOverviewCard extends ConsumerWidget {
  const _ComplianceOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(complianceOverviewProvider);

    return _CardContainer(
      child: overview.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _EmptyPanelInline(
          message: 'Không thể tải dữ liệu tuân thủ',
          onRetry: () => ref.invalidate(complianceOverviewProvider),
        ),
        data: (overview) {
          if (overview.total == 0) {
            return const _EmptyPanelInline(message: 'Chưa có dữ liệu tuân thủ');
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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

class _EmptyPanelInline extends StatelessWidget {
  const _EmptyPanelInline({required this.message, this.onRetry});
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
              fontSize: 13,
              color: Color(0xFF424656),
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
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

// ─────────────────────────────────────────────────────────────────────────────
// Patient selection list — horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────

class _PatientSelectionList extends StatelessWidget {
  const _PatientSelectionList({
    required this.patients,
    required this.selectedCaseId,
    required this.onSelect,
  });

  final List<PatientSummary> patients;
  final String? selectedCaseId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const _EmptyPanel(message: 'Chưa có người bệnh nào');
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: patients.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final patient = patients[index];
          final isSelected = patient.code == selectedCaseId;
          return _PatientChip(
            patient: patient,
            isSelected: isSelected,
            onTap: () => onSelect(patient.code),
          );
        },
      ),
    );
  }
}

class _PatientChip extends StatelessWidget {
  const _PatientChip({
    required this.patient,
    required this.isSelected,
    required this.onTap,
  });

  final PatientSummary patient;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: patient.status.badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: patient.status.badgeText,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              patient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF191B24),
              ),
            ),
            Text(
              patient.pod,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Color(0xFF727687),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail tab switcher
// ─────────────────────────────────────────────────────────────────────────────

class _DetailTabSwitcher extends StatelessWidget {
  const _DetailTabSwitcher({required this.tab, required this.onChanged});
  final _DetailTab tab;
  final ValueChanged<_DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEDFA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Độ tuân thủ',
              isActive: tab == _DetailTab.compliance,
              onTap: () => onChanged(_DetailTab.compliance),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Đánh giá cuối ngày',
              isActive: tab == _DetailTab.assessment,
              onTap: () => onChanged(_DetailTab.assessment),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : const Color(0xFF727687),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compliance stats panel — checklist + counters
// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceStatsPanel extends ConsumerWidget {
  const _ComplianceStatsPanel({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compliance = ref.watch(patientComplianceProvider(caseId));

    return compliance.when(
      loading: () => const _CardContainer(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => _EmptyPanel(
        message: 'Không thể tải dữ liệu tuân thủ',
        onRetry: () => ref.invalidate(patientComplianceProvider(caseId)),
      ),
      data: (data) => _CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checklist',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF727687),
                  ),
                ),
                _ComplianceStatusBadge(isCompliant: data.isCompliant),
              ],
            ),
            const SizedBox(height: 10),
            _ChecklistRow(
              label: 'Đã xem hướng dẫn POD',
              done: data.viewedGuidance,
            ),
            const SizedBox(height: 8),
            _ChecklistRow(
              label: 'Đã xem giáo dục sức khỏe',
              done: data.viewedEducation,
            ),
            const SizedBox(height: 18),
            const Text(
              'Số liệu',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF727687),
              ),
            ),
            const SizedBox(height: 10),
            _CounterRow(
              label: 'Số đánh giá đã hoàn thành',
              value: data.assessmentCompletedCount,
            ),
            const SizedBox(height: 8),
            _CounterRow(label: 'Số lần nhắc nhở', value: data.reminderCount),
            const SizedBox(height: 8),
            _CounterRow(
              label: 'Số lần truy cập ứng dụng',
              value: data.appAccessCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplianceStatusBadge extends StatelessWidget {
  const _ComplianceStatusBadge({required this.isCompliant});
  final bool isCompliant;

  @override
  Widget build(BuildContext context) {
    final color = isCompliant ? AppColors.statusNormal : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isCompliant ? 'Tuân thủ' : 'Không tuân thủ',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 18,
          color: done ? AppColors.statusNormal : const Color(0xFFC2C6D8),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: done ? const Color(0xFF191B24) : const Color(0xFF727687),
          ),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.label, required this.value});
  final String label;
  final int value;

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
            color: Color(0xFF424656),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191B24),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// End-of-day assessment panel — questions x POD grid
// ─────────────────────────────────────────────────────────────────────────────

class _EndOfDayAssessmentPanel extends ConsumerWidget {
  const _EndOfDayAssessmentPanel({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrix = ref.watch(assessmentMatrixProvider(caseId));

    return matrix.when(
      loading: () => const _CardContainer(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => _EmptyPanel(
        message: 'Không thể tải bảng đánh giá',
        onRetry: () => ref.invalidate(assessmentMatrixProvider(caseId)),
      ),
      data: (matrix) {
        if (matrix.questions.isEmpty) {
          return const _EmptyPanel(
            message: 'Chưa có đánh giá cuối ngày cho người bệnh này',
          );
        }
        return _CardContainer(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _AssessmentMatrixTable(matrix: matrix),
          ),
        );
      },
    );
  }
}

class _AssessmentMatrixTable extends StatelessWidget {
  const _AssessmentMatrixTable({required this.matrix});
  final AssessmentMatrix matrix;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF424656),
    );
    const cellStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      color: Color(0xFF191B24),
    );

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 44,
      columnSpacing: 20,
      columns: [
        const DataColumn(label: Text('Chỉ số', style: headerStyle)),
        ...matrix.pods.map(
          (pod) => DataColumn(label: Text('POD$pod', style: headerStyle)),
        ),
      ],
      rows: matrix.questions.map((question) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 140,
                child: Text(
                  question.questionText,
                  style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ...matrix.pods.map(
              (pod) => DataCell(
                Text(
                  question.scoreForPod(pod)?.toString() ?? '--',
                  style: cellStyle,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
