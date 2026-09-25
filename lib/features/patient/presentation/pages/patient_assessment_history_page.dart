import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/patient/domain/models/symptom_history_model.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';
import 'package:poms/features/patient/presentation/providers/patient_assessment_history_provider.dart';

class PatientAssessmentHistoryPage extends ConsumerWidget {
  const PatientAssessmentHistoryPage({super.key});

  Future<void> _pickAssessmentDate(
    BuildContext context,
    WidgetRef ref,
    List<PatientHistoryDayGroup> dayGroups,
    DateTime? selectedDate,
  ) async {
    if (dayGroups.isEmpty) return;

    final sortedDates = dayGroups.map((g) => g.date).toList()..sort();
    final initialDate = selectedDate ?? sortedDates.last;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: sortedDates.first,
      lastDate: sortedDates.last,
      helpText: 'Chọn ngày đánh giá',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedDate == null) return;

    ref.read(selectedHistoryDateProvider.notifier).state = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayGroups = ref.watch(patientDayGroupsProvider);
    final selectedDate = ref.watch(selectedHistoryDateProvider);
    final activeGroup = ref.watch(activeHistoryDayGroupProvider);
    final currentPod = ref.watch(currentPodProvider).valueOrNull;
    final activeLog = ref.watch(activeAssessmentLogProvider);
    final timelineAsync = ref.watch(patientPodTimelineApiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onSurface,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.patientDashboard);
            }
          },
        ),
        title: const Text(
          'Lịch sử đánh giá',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              ref.invalidate(patientPodTimelineApiProvider);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            tooltip: 'Thông báo hệ thống',
            onPressed: () => context.push(AppRoutes.patientNotifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 56,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải lịch sử đánh giá:\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(patientPodTimelineApiProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (_) {
            if (dayGroups.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có dữ liệu đánh giá.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              );
            }

            final currentActiveGroup = activeGroup ?? dayGroups.last;
            final currentActiveLog = activeLog ?? currentActiveGroup.latestLog;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(patientPodTimelineApiProvider);
                await ref.read(patientPodTimelineApiProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar for picking dates (nurse / doctor style)
                    _AssessmentDateSearchBar(
                      selectedDate: selectedDate,
                      onTap: () => _pickAssessmentDate(
                        context,
                        ref,
                        dayGroups,
                        selectedDate,
                      ),
                      onClear: selectedDate == null
                          ? null
                          : () {
                              ref
                                      .read(
                                        selectedHistoryDateProvider.notifier,
                                      )
                                      .state =
                                  null;
                            },
                    ),
                    const SizedBox(height: 16),

                    // 2. Horizontal timeline date picker (nurse / doctor style)
                    _AssessmentHistoryTimeline(
                      activeDate: currentActiveGroup.date,
                      dayGroups: dayGroups,
                      onSelectDay: (group) {
                        ref.read(selectedHistoryDateProvider.notifier).state =
                            group.date;
                        ref.read(selectedAssessmentIdProvider.notifier).state =
                            null;
                      },
                    ),

                    // 3. Intra-day selector if multiple assessments exist on selected day
                    if (currentActiveGroup.logs.length > 1) ...[
                      const SizedBox(height: 12),
                      _AssessmentIntraDayTimeSelector(
                        logs: currentActiveGroup.logs,
                        activeLog: currentActiveLog,
                        onSelectLog: (log) {
                          if (log.assessmentId != null) {
                            ref
                                    .read(selectedAssessmentIdProvider.notifier)
                                    .state =
                                log.assessmentId;
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 4. Daily Overview Summary Card
                    _DailyOverviewSummaryCard(log: currentActiveLog),
                    const SizedBox(height: 20),

                    // 5. Symptom Assessment Detail List or Empty State
                    if (currentActiveLog.isAssessed) ...[
                      const Text(
                        'Chi tiết đánh giá',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentActiveLog.symptoms.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = currentActiveLog.symptoms[index];
                          return _SymptomDetailCard(item: item);
                        },
                      ),
                    ] else ...[
                      _UnassessedDateCard(
                        date: currentActiveGroup.date,
                        podNumber: currentActiveGroup.podNumber,
                        canSubmitAssessment:
                            currentPod?.canSubmitAssessment ?? true,
                        assessmentDisabledReason:
                            currentPod?.assessmentDisabledReason,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Search Bar (Nurse/Doctor Style)
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentDateSearchBar extends StatelessWidget {
  const _AssessmentDateSearchBar({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate
                    ? 'Ngày chọn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                    : 'Chọn ngày xem lịch sử đánh giá...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: hasDate ? FontWeight.w700 : FontWeight.w500,
                  color: hasDate
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else
              const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Timeline Date Picker (Nurse/Doctor Style with Auto-Scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentHistoryTimeline extends StatefulWidget {
  const _AssessmentHistoryTimeline({
    required this.activeDate,
    required this.dayGroups,
    required this.onSelectDay,
  });

  final DateTime activeDate;
  final List<PatientHistoryDayGroup> dayGroups;
  final ValueChanged<PatientHistoryDayGroup> onSelectDay;

  @override
  State<_AssessmentHistoryTimeline> createState() =>
      _AssessmentHistoryTimelineState();
}

class _AssessmentHistoryTimelineState
    extends State<_AssessmentHistoryTimeline> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveDate());
  }

  @override
  void didUpdateWidget(covariant _AssessmentHistoryTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.activeDate, widget.activeDate) ||
        oldWidget.dayGroups.length != widget.dayGroups.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToActiveDate(),
      );
    }
  }

  void _scrollToActiveDate() {
    if (!_scrollController.hasClients || widget.dayGroups.isEmpty) return;

    final index = widget.dayGroups.indexWhere(
      (g) => isSameDay(g.date, widget.activeDate),
    );

    if (index == -1) return;

    if (index == widget.dayGroups.length - 1) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      const itemWidth = 72.0;
      const separatorWidth = 10.0;
      final targetOffset = index * (itemWidth + separatorWidth);
      final maxExtent = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxExtent);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.dayGroups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = widget.dayGroups[index];
          final selected = isSameDay(group.date, widget.activeDate);

          return _AssessmentHistoryCard(
            dayGroup: group,
            selected: selected,
            onTap: () => widget.onSelectDay(group),
          );
        },
      ),
    );
  }
}

class _AssessmentHistoryCard extends StatelessWidget {
  const _AssessmentHistoryCard({
    required this.dayGroup,
    required this.selected,
    required this.onTap,
  });

  final PatientHistoryDayGroup dayGroup;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM').format(dayGroup.date);
    final repLog = dayGroup.latestLog;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateStr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : const Color(0xFF191B24),
              ),
            ),
            const SizedBox(height: 4),
            _AssessmentColorDot(
              triage: repLog.triageColor,
              isAssessed: dayGroup.isAssessed,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentColorDot extends StatelessWidget {
  const _AssessmentColorDot({required this.triage, required this.isAssessed});

  final TriageColor triage;
  final bool isAssessed;

  @override
  Widget build(BuildContext context) {
    if (!isAssessed) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      );
    }

    final color = switch (triage) {
      TriageColor.green => const Color(0xFF16A34A),
      TriageColor.yellow => const Color(0xFFD97706),
      TriageColor.red => const Color(0xFFDC2626),
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intra-Day Time Selector Tabs
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentIntraDayTimeSelector extends StatelessWidget {
  const _AssessmentIntraDayTimeSelector({
    required this.logs,
    required this.activeLog,
    required this.onSelectLog,
  });

  final List<AssessmentHistoryLog> logs;
  final AssessmentHistoryLog activeLog;
  final ValueChanged<AssessmentHistoryLog> onSelectLog;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: logs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final log = logs[index];
          final timeStr = DateFormat('HH:mm').format(log.date);
          final isSelected = log == activeLog;

          return ChoiceChip(
            label: Text(
              timeStr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: const Color(0xFFF1F5F9),
            onSelected: (_) => onSelectLog(log),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Overview Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _DailyOverviewSummaryCard extends StatelessWidget {
  const _DailyOverviewSummaryCard({required this.log});

  final AssessmentHistoryLog log;

  String _formatFullDate(DateTime date) {
    final weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayName = weekdays[date.weekday - 1];
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString().padLeft(2, '0');
    return '$dayName, $dayStr/$monthStr/${date.year}';
  }

  Color _recoveryBadgeColor(TriageColor triage, bool isAssessed) {
    if (!isAssessed) return const Color(0xFF6B7280);
    return switch (triage) {
      TriageColor.green => const Color(0xFF10B981),
      TriageColor.yellow => const Color(0xFFF59E0B),
      TriageColor.red => const Color(0xFFEF4444),
    };
  }

  Color _recoveryBadgeBg(TriageColor triage, bool isAssessed) {
    if (!isAssessed) return const Color(0xFFF3F4F6);
    return switch (triage) {
      TriageColor.green => const Color(0xFFE6F9F1),
      TriageColor.yellow => const Color(0xFFFFF7E6),
      TriageColor.red => const Color(0xFFFEE2E2),
    };
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _recoveryBadgeColor(log.triageColor, log.isAssessed);
    final badgeBg = _recoveryBadgeBg(log.triageColor, log.isAssessed);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _formatFullDate(log.date),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  log.recoveryStatusTag,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            log.isReassessment
                ? 'Đã được đánh giá lại bởi điều dưỡng.'
                : (log.isAssessed
                      ? 'Đã hoàn thành ${log.completedCount}/${log.totalCount} mục đánh giá triệu chứng.'
                      : 'Chưa thực hiện khảo sát triệu chứng cho ngày này.'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom Detail Card
// ─────────────────────────────────────────────────────────────────────────────

class _SymptomDetailCard extends StatelessWidget {
  const _SymptomDetailCard({required this.item});

  final SymptomHistoryDetail item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.status.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.status.badgeTextColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.symptomName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.status.badgeBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.status.badgeTextColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              item.resultBadge,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.status.badgeTextColor,
              ),
            ),
          ),
          if (item.shortDescription.isNotEmpty &&
              item.shortDescription != 'Lựa chọn: ${item.resultBadge}') ...[
            const SizedBox(height: 6),
            Text(
              item.shortDescription,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.35,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unassessed Date Card
// ─────────────────────────────────────────────────────────────────────────────

class _UnassessedDateCard extends StatelessWidget {
  const _UnassessedDateCard({
    required this.date,
    required this.podNumber,
    required this.canSubmitAssessment,
    this.assessmentDisabledReason,
  });

  final DateTime date;
  final int podNumber;

  /// Trạng thái khóa đánh giá thực tế của bệnh nhân (RED alert cooldown, ERAS
  /// đã hoàn thành, ngoài khung giờ cố định…) — khác với isFuture/isPast bên
  /// dưới vốn chỉ so ngày được chọn với hôm nay.
  final bool canSubmitAssessment;
  final String? assessmentDisabledReason;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    final isFuture = selectedDay.isAfter(today);
    final isPast = selectedDay.isBefore(today);
    final isToday = selectedDay.isAtSameMomentAs(today);
    final isLockedToday = isToday && !canSubmitAssessment;
    final canTapButton = isToday && canSubmitAssessment;

    final String titleMessage;
    final String bodyMessage;
    final String buttonLabel;
    final IconData buttonIcon;

    if (isFuture) {
      titleMessage = 'Chưa đến ngày đánh giá';
      bodyMessage =
          'Bạn chưa thể thực hiện bài khảo sát cho ngày này. Vui lòng quay lại vào đúng ngày.';
      buttonLabel = 'Chưa đến ngày đánh giá';
      buttonIcon = Icons.lock_clock_outlined;
    } else if (isPast) {
      titleMessage = 'Đã quá hạn đánh giá';
      bodyMessage =
          'Bài khảo sát theo dõi triệu chứng cho ngày này đã quá hạn. Bạn chỉ có thể thực hiện bài đánh giá cho ngày hiện tại.';
      buttonLabel = 'Đã quá hạn đánh giá';
      buttonIcon = Icons.history_toggle_off_rounded;
    } else if (isLockedToday) {
      titleMessage = 'Bài đánh giá tạm thời chưa thể thực hiện';
      bodyMessage =
          assessmentDisabledReason ??
          'Bài đánh giá hiện tại chưa thể thực hiện.';
      buttonLabel = 'Tạm khóa';
      buttonIcon = Icons.lock_clock_rounded;
    } else {
      titleMessage = 'Chưa có nhật ký đánh giá';
      bodyMessage =
          'Bạn chưa hoàn thành bài khảo sát theo dõi triệu chứng hàng ngày cho hôm nay.';
      buttonLabel = 'Thực hiện đánh giá ngay';
      buttonIcon = Icons.assignment_turned_in_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF9)),
      ),
      child: Column(
        children: [
          Icon(
            isFuture
                ? Icons.event_available_outlined
                : isPast
                ? Icons.history_toggle_off_rounded
                : isLockedToday
                ? Icons.lock_clock_rounded
                : Icons.assignment_late_outlined,
            size: 48,
            color: (isFuture || isPast || isLockedToday)
                ? AppColors.onSurfaceVariant.withValues(alpha: 0.6)
                : AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            titleMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bodyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canTapButton
                  ? () => context.push(AppRoutes.patientAssessment)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: Icon(buttonIcon, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
