import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/domain/models/symptom_history_model.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';
import 'package:poms/features/patient/presentation/providers/survey_provider.dart';

/// Single source of truth for the currently selected date in History Calendar
final selectedHistoryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Fetch full POD timeline history from backend API GET /symptom-surveys/patient/:caseId/history
final patientPodTimelineApiProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final user = ref.watch(authNotifierProvider).user;
      final caseId = user?.caseId;
      if (caseId == null || caseId.isEmpty) return {};
      final dataSource = ref.watch(surveyRemoteDataSourceProvider);
      return await dataSource.getPatientPodHistory(caseId);
    });

/// List of days displayed in the horizontal calendar selector (strictly PAST TO TODAY, NO FUTURE DATES)
final historyCalendarDaysProvider = Provider<List<DateTime>>((ref) {
  final today = DateTime.now();
  final baseDate = DateTime(today.year, today.month, today.day);

  final timelineAsync = ref.watch(patientPodTimelineApiProvider).valueOrNull;
  final historyList = timelineAsync?['history'] as List<dynamic>?;

  if (historyList != null && historyList.isNotEmpty) {
    final dates = <DateTime>[];
    for (final item in historyList) {
      if (item is Map<String, dynamic> && item['date'] != null) {
        final d = DateTime.parse(item['date'].toString());
        final normalized = DateTime(d.year, d.month, d.day);
        if (!normalized.isAfter(baseDate) && !dates.contains(normalized)) {
          dates.add(normalized);
        }
      }
    }
    if (dates.isNotEmpty) {
      dates.sort();
      return dates;
    }
  }

  // Fallback: Generate past 5 days up to TODAY (POD 0..currentPod, capped at today)
  return List.generate(
    5,
    (index) => baseDate.subtract(Duration(days: 4 - index)),
  );
});

/// Query history assessment log for the selected date
final patientAssessmentHistoryProvider = Provider.family<AssessmentHistoryLog, DateTime>((
  ref,
  date,
) {
  final selectedDay = DateTime(date.year, date.month, date.day);
  final timelineAsync = ref.watch(patientPodTimelineApiProvider).valueOrNull;
  final historyList = timelineAsync?['history'] as List<dynamic>?;

  if (historyList != null && historyList.isNotEmpty) {
    for (final item in historyList) {
      if (item is Map<String, dynamic> && item['date'] != null) {
        final evalDate = DateTime.parse(item['date'].toString());
        final itemDay = DateTime(evalDate.year, evalDate.month, evalDate.day);

        if (itemDay.isAtSameMomentAs(selectedDay)) {
          final isAssessed = item['isAssessed'] as bool? ?? false;
          final podNum = (item['podNumber'] as int? ?? 0).clamp(0, 5);
          final triageStr = (item['triageColor'] as String? ?? 'GREEN')
              .toUpperCase();
          final triageColor = triageStr == 'RED'
              ? TriageColor.red
              : triageStr == 'YELLOW'
              ? TriageColor.yellow
              : TriageColor.green;

          final detailsRaw = item['details'] as List<dynamic>? ?? [];
          final symptoms = detailsRaw.map((d) {
            final score = d['scoreEarned'] as int? ?? 0;
            final severity = score == 0
                ? SymptomSeverityStatus.green
                : score == 1
                ? SymptomSeverityStatus.yellow
                : SymptomSeverityStatus.red;

            return SymptomHistoryDetail(
              questionId: d['questionId'] as int? ?? 0,
              symptomName: d['questionText'] as String? ?? 'Câu hỏi',
              shortDescription: 'Lựa chọn: ${d['optionText'] ?? 'Đã ghi nhận'}',
              resultBadge: '${d['optionText'] ?? ''} ($score điểm)',
              status: severity,
              icon: _getIconForQuestion(d['questionId'] as int? ?? 0),
            );
          }).toList();

          return AssessmentHistoryLog(
            date: date,
            podNumber: podNum,
            isAssessed: isAssessed,
            triageColor: triageColor,
            recoveryStatusTag:
                item['recoveryStatusTag'] as String? ??
                (isAssessed ? 'Hồi phục tốt' : 'Chưa đánh giá'),
            completedCount:
                item['completedCount'] as int? ?? (isAssessed ? 5 : 0),
            totalCount: item['totalCount'] as int? ?? 5,
            symptoms: symptoms,
            medicalFeedback: item['medicalFeedback'] as String?,
          );
        }
      }
    }
  }

  // Local fallback calculation if backend API timeline has no entry for this date
  final currentPodState = ref.watch(currentPodProvider).valueOrNull;
  final currentPodNum = (currentPodState?.currentPod ?? 0).clamp(0, 7);
  final today = DateTime.now();
  final baseToday = DateTime(today.year, today.month, today.day);

  final diffDays = selectedDay.difference(baseToday).inDays;
  final podForDate = (currentPodNum + diffDays).clamp(0, 7);

  return AssessmentHistoryLog(
    date: date,
    podNumber: podForDate,
    isAssessed: false,
    triageColor: TriageColor.green,
    recoveryStatusTag: 'Chưa đánh giá',
    completedCount: 0,
    totalCount: 5,
    symptoms: const [],
    medicalFeedback: null,
  );
});

IconData _getIconForQuestion(int questionId) {
  switch (questionId) {
    case 1:
      return Icons.sick_outlined;
    case 2:
      return Icons.sentiment_neutral_outlined;
    case 3:
      return Icons.restaurant_outlined;
    case 4:
      return Icons.directions_walk_outlined;
    case 5:
      return Icons.water_drop_outlined;
    default:
      return Icons.assignment_outlined;
  }
}
