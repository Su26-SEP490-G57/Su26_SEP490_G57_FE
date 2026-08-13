import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/patient/domain/models/symptom_history_model.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/presentation/providers/patient_assessment_history_provider.dart';

class PatientAssessmentHistoryPage extends ConsumerWidget {
  const PatientAssessmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedHistoryDateProvider);
    final calendarDays = ref.watch(historyCalendarDaysProvider);
    final historyLog = ref.watch(
      patientAssessmentHistoryProvider(selectedDate),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Dynamic Month/Year Indicator & Horizontal Calendar Picker
            _MonthYearAndCalendarHeader(
              selectedDate: selectedDate,
              calendarDays: calendarDays,
              onDateSelected: (date) {
                ref.read(selectedHistoryDateProvider.notifier).state = date;
              },
            ),
            const SizedBox(height: 16),

            // Scrollable detail content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).padding.bottom + 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Overview Summary Card
                    _DailyOverviewSummaryCard(log: historyLog),
                    const SizedBox(height: 20),

                    // Symptom Assessment Detail List or Empty State
                    if (historyLog.isAssessed) ...[
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

                      // Dynamic Vertical Symptom List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historyLog.symptoms.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = historyLog.symptoms[index];
                          return _SymptomDetailCard(item: item);
                        },
                      ),
                    ] else ...[
                      _UnassessedDateCard(
                        date: selectedDate,
                        podNumber: historyLog.podNumber,
                      ),
                    ],
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
// Month/Year Indicator & Horizontal Date Picker Selector
// ─────────────────────────────────────────────────────────────────────────────

class _MonthYearAndCalendarHeader extends StatelessWidget {
  const _MonthYearAndCalendarHeader({
    required this.selectedDate,
    required this.calendarDays,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<DateTime> calendarDays;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final monthYearText = 'Tháng ${selectedDate.month} ${selectedDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month/Year Indicator Label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthYearText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Calendar Scrollable Row
        SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: calendarDays.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = calendarDays[index];
              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;

              return _DayPickerItem(
                date: date,
                isSelected: isSelected,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayPickerItem extends StatelessWidget {
  const _DayPickerItem({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'T2',
      DateTime.tuesday => 'T3',
      DateTime.wednesday => 'T4',
      DateTime.thursday => 'T5',
      DateTime.friday => 'T6',
      DateTime.saturday => 'T7',
      DateTime.sunday => 'CN',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dayStr = date.day.toString().padLeft(2, '0');
    final weekdayStr = _weekdayLabel(date.weekday);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
              weekdayStr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayStr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
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
          // Row 1: Full Date & POD Milestone Tag
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'POD ${log.podNumber}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Recovery Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
              const Spacer(),
              Text(
                '${log.completionPercentage}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Progress Bar & Target Progress Text
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              tween: Tween<double>(
                begin: 0,
                end: log.completionPercentage / 100.0,
              ),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEDEDF9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            log.isAssessed
                ? 'Đã hoàn thành ${log.completedCount}/${log.totalCount} mục đánh giá triệu chứng.'
                : 'Chưa thực hiện khảo sát triệu chứng cho ngày này.',
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
              // Icon Container
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

              // Symptom Name
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

          // Color-Coded Result Badge (Flexibly wraps, never overflows)
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
  const _UnassessedDateCard({required this.date, required this.podNumber});

  final DateTime date;
  final int podNumber;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    final isFuture = selectedDay.isAfter(today);
    final isPast = selectedDay.isBefore(today);
    final isToday = selectedDay.isAtSameMomentAs(today);

    // Hard boundary limit: ERAS pathway is strictly POD 0 to 5 max
    final safePodNumber = podNumber.clamp(0, 5);

    final String titleMessage;
    final String bodyMessage;
    final String buttonLabel;
    final IconData buttonIcon;

    if (isFuture) {
      titleMessage = 'Chưa đến ngày đánh giá (POD $safePodNumber)';
      bodyMessage =
          'Bạn chưa thể thực hiện bài khảo sát cho ngày này. Vui lòng quay lại vào đúng ngày.';
      buttonLabel = 'Chưa đến ngày đánh giá';
      buttonIcon = Icons.lock_clock_outlined;
    } else if (isPast) {
      titleMessage = 'Đã quá hạn đánh giá (POD $safePodNumber)';
      bodyMessage =
          'Bài khảo sát theo dõi triệu chứng cho ngày này đã quá hạn. Bạn chỉ có thể thực hiện bài đánh giá cho ngày hiện tại.';
      buttonLabel = 'Đã quá hạn đánh giá';
      buttonIcon = Icons.history_toggle_off_rounded;
    } else {
      titleMessage = 'Chưa có nhật ký đánh giá (POD $safePodNumber)';
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
                : Icons.assignment_late_outlined,
            size: 48,
            color: (isFuture || isPast)
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
              onPressed: isToday
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
