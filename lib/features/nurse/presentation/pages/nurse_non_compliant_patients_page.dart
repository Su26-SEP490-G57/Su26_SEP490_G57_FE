import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance_summary.dart';
import 'package:poms/features/nurse/presentation/providers/noncompliant_patients_provider.dart';
import 'package:poms/features/nurse/presentation/widgets/patient_pagination.dart';

class NurseNonCompliantPatientsPage extends ConsumerStatefulWidget {
  const NurseNonCompliantPatientsPage({super.key});

  @override
  ConsumerState<NurseNonCompliantPatientsPage> createState() =>
      _NurseNonCompliantPatientsPageState();
}

class _NurseNonCompliantPatientsPageState
    extends ConsumerState<NurseNonCompliantPatientsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetPage() {
    ref.read(nonCompliantPageProvider.notifier).state = 1;
  }

  void _showOverallStatusPicker() {
    final current = ref.read(nonCompliantFiltersProvider).overallStatus;
    _showSimplePicker<OverallStatusFilter>(
      title: 'Trạng thái tuân thủ',
      options: OverallStatusFilter.values,
      optionLabel: (v) => v.label,
      selected: current,
      onSelect: (v) {
        ref.read(nonCompliantFiltersProvider.notifier).state = ref
            .read(nonCompliantFiltersProvider)
            .copyWith(overallStatus: v);
        _resetPage();
      },
    );
  }

  void _showAssessmentSlotPicker() {
    final current = ref.read(nonCompliantFiltersProvider).assessmentSlot;
    _showSimplePicker<AssessmentSlotFilter>(
      title: 'Khung giờ đánh giá định kỳ',
      options: AssessmentSlotFilter.values,
      optionLabel: (v) => v.label,
      selected: current,
      onSelect: (v) {
        ref.read(nonCompliantFiltersProvider.notifier).state = ref
            .read(nonCompliantFiltersProvider)
            .copyWith(assessmentSlot: v);
        _resetPage();
      },
    );
  }

  void _showSimplePicker<T>({
    required String title,
    required List<T> options,
    required String Function(T) optionLabel,
    required T selected,
    required ValueChanged<T> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF8FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC2C6D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191B24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final isSelected = option == selected;
              return _PickerItem(
                label: optionLabel(option),
                isSelected: isSelected,
                onTap: () {
                  onSelect(option);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _toggleDietaryNotViewed() {
    final filters = ref.read(nonCompliantFiltersProvider);
    ref.read(nonCompliantFiltersProvider.notifier).state = filters.copyWith(
      dietaryNotViewed: !filters.dietaryNotViewed,
    );
    _resetPage();
  }

  void _toggleHealthEducationNotViewed() {
    final filters = ref.read(nonCompliantFiltersProvider);
    ref.read(nonCompliantFiltersProvider.notifier).state = filters.copyWith(
      healthEducationNotViewed: !filters.healthEducationNotViewed,
    );
    _resetPage();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(complianceListProvider);
    final filters = ref.watch(nonCompliantFiltersProvider);
    final page = ref.watch(nonCompliantPageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: Column(
        children: [
          _TopAppBar(onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _SearchBar(
                  controller: _searchController,
                  onChanged: (v) {
                    ref.read(nonCompliantSearchQueryProvider.notifier).state =
                        v;
                    _resetPage();
                  },
                ),
                const SizedBox(height: 12),
                _FilterChipsRow(
                  filters: filters,
                  onOverallStatusTap: _showOverallStatusPicker,
                  onAssessmentSlotTap: _showAssessmentSlotPicker,
                  onDietaryToggle: _toggleDietaryNotViewed,
                  onHealthEducationToggle: _toggleHealthEducationNotViewed,
                ),
                const SizedBox(height: 12),
                listAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('Lỗi: $err')),
                  ),
                  data: (result) {
                    if (result.items.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Không có người bệnh phù hợp bộ lọc.'),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Tổng: ${result.total} người bệnh',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Color(0xFF727687),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...result.items.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PatientComplianceCard(
                              data: p,
                              onTap: () => context.push(
                                AppRoutes.nursePatientDetailPath(p.caseId),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PatientPagination(
                          currentPage: page,
                          totalPages: result.totalPages,
                          startIndex: result.total == 0
                              ? 0
                              : (page - 1) * result.limit + 1,
                          endIndex: (page * result.limit).clamp(
                            0,
                            result.total,
                          ),
                          total: result.total,
                          onPrevious: () {
                            if (page <= 1) return;
                            ref.read(nonCompliantPageProvider.notifier).state =
                                page - 1;
                          },
                          onNext: () {
                            if (page >= result.totalPages) return;
                            ref.read(nonCompliantPageProvider.notifier).state =
                                page + 1;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: onBack,
              ),
              const Expanded(
                child: Text(
                  'Người bệnh không tuân thủ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C6D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF191B24),
        ),
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm người bệnh...',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF727687),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color(0xFF727687),
            size: 22,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filters,
    required this.onOverallStatusTap,
    required this.onAssessmentSlotTap,
    required this.onDietaryToggle,
    required this.onHealthEducationToggle,
  });

  final NonCompliantFilters filters;
  final VoidCallback onOverallStatusTap;
  final VoidCallback onAssessmentSlotTap;
  final VoidCallback onDietaryToggle;
  final VoidCallback onHealthEducationToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DropdownFilterChip(
            label: filters.overallStatus.label,
            isActive: filters.overallStatus != OverallStatusFilter.all,
            onTap: onOverallStatusTap,
          ),
          const SizedBox(width: 8),
          _DropdownFilterChip(
            label: filters.assessmentSlot.label,
            isActive: filters.assessmentSlot != AssessmentSlotFilter.any,
            onTap: onAssessmentSlotTap,
          ),
          const SizedBox(width: 8),
          _ToggleFilterChip(
            label: 'Chưa xem hướng dẫn ăn',
            isActive: filters.dietaryNotViewed,
            onTap: onDietaryToggle,
          ),
          const SizedBox(width: 8),
          _ToggleFilterChip(
            label: 'Chưa xem giáo dục sức khỏe',
            isActive: filters.healthEducationNotViewed,
            onTap: onHealthEducationToggle,
          ),
        ],
      ),
    );
  }
}

class _DropdownFilterChip extends StatelessWidget {
  const _DropdownFilterChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFE6E7F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFC2C6D8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : const Color(0xFF424656),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: isActive ? AppColors.primary : const Color(0xFF424656),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleFilterChip extends StatelessWidget {
  const _ToggleFilterChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFE6E7F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFC2C6D8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : const Color(0xFF424656),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF191B24),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient compliance card
// ─────────────────────────────────────────────────────────────────────────────

class _PatientComplianceCard extends StatelessWidget {
  const _PatientComplianceCard({required this.data, required this.onTap});

  final PatientComplianceSummary data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC2C6D8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6E7F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191B24),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.roomBed ?? '—'} • ${data.podLabel}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF424656),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ComplianceStatusBadge(isCompliant: data.isCompliant),
                    const SizedBox(height: 4),
                    Text(
                      '${(data.complianceRate * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChecklistChip(
                  label: 'Hướng dẫn ăn',
                  done: data.viewedGuidance,
                ),
                _ChecklistChip(
                  label: 'Giáo dục sức khỏe',
                  done: data.viewedEducation,
                ),
                _AssessmentChip(
                  morning: data.morningAssessmentStatus,
                  afternoon: data.afternoonAssessmentStatus,
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isCompliant ? 'Tuân thủ' : 'Không tuân thủ',
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

/// Chip đơn giản: check_circle (xanh) khi đã hoàn thành, circle_outlined
/// (xám) khi chưa — cùng convention với `_ChecklistRow` ở màn chi tiết BN.
class _ChecklistChip extends StatelessWidget {
  const _ChecklistChip({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.statusNormal : const Color(0xFF727687);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? AppColors.statusNormal.withValues(alpha: 0.08)
            : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: done ? AppColors.statusNormal : const Color(0xFFC2C6D8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip "Đánh giá định kỳ" — gộp trạng thái 2 khung giờ sáng/chiều.
class _AssessmentChip extends StatelessWidget {
  const _AssessmentChip({required this.morning, required this.afternoon});

  final ScheduledAssessmentStatus? morning;
  final ScheduledAssessmentStatus? afternoon;

  (IconData, Color) _iconFor(ScheduledAssessmentStatus? status) {
    return switch (status) {
      ScheduledAssessmentStatus.completed => (
        Icons.check_circle_rounded,
        AppColors.statusNormal,
      ),
      ScheduledAssessmentStatus.missed => (
        Icons.cancel_rounded,
        AppColors.statusCritical,
      ),
      ScheduledAssessmentStatus.pending => (
        Icons.circle_outlined,
        AppColors.statusWarning,
      ),
      null => (Icons.remove_circle_outline, AppColors.statusUnknown),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (morningIcon, morningColor) = _iconFor(morning);
    final (afternoonIcon, afternoonColor) = _iconFor(afternoon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Đánh giá định kỳ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424656),
            ),
          ),
          const SizedBox(width: 6),
          Icon(morningIcon, size: 14, color: morningColor),
          const SizedBox(width: 2),
          const Text('S', style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
          const SizedBox(width: 6),
          Icon(afternoonIcon, size: 14, color: afternoonColor),
          const SizedBox(width: 2),
          const Text('C', style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
        ],
      ),
    );
  }
}
