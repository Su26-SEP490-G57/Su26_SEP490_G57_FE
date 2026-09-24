import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/domain/models/symptom_history_model.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/presentation/providers/survey_provider.dart';

/// Single source of truth for the currently selected date in History (null = auto select latest)
final selectedHistoryDateProvider = StateProvider<DateTime?>((ref) => null);

/// Single source of truth for selected assessment ID on an intraday date (null = latest)
final selectedAssessmentIdProvider = StateProvider<int?>((ref) => null);

/// Fetch full POD timeline history from backend API GET /symptom-surveys/patient/:caseId/history
final patientPodTimelineApiProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final user = ref.watch(authNotifierProvider).user;
      final caseId = user?.caseId;
      if (caseId == null || caseId.isEmpty) return {};
      final dataSource = ref.watch(surveyRemoteDataSourceProvider);
      return await dataSource.getPatientPodHistory(caseId);
    });

DateTime _toVietnamTime(DateTime dt) {
  return dt.toUtc().add(const Duration(hours: 7));
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Represents a group of assessments on a single calendar day
class PatientHistoryDayGroup {
  const PatientHistoryDayGroup({
    required this.date,
    required this.podNumber,
    required this.logs,
  });

  final DateTime date;
  final int podNumber;
  final List<AssessmentHistoryLog> logs;

  AssessmentHistoryLog get latestLog => logs.last;
  bool get isAssessed => logs.any((l) => l.isAssessed);
}

/// Computes grouped timeline history items parsed in Vietnam Local Time (GMT+7)
final patientDayGroupsProvider = Provider<List<PatientHistoryDayGroup>>((ref) {
  final timelineAsync = ref.watch(patientPodTimelineApiProvider).valueOrNull;
  final historyList = timelineAsync?['history'] as List<dynamic>?;

  if (historyList == null || historyList.isEmpty) {
    return [];
  }

  final map = <DateTime, List<AssessmentHistoryLog>>{};
  final podMap = <DateTime, int>{};

  for (final item in historyList) {
    if (item is Map<String, dynamic> && item['date'] != null) {
      final parsed = DateTime.parse(item['date'].toString());
      final vnTime = _toVietnamTime(parsed);
      final dayKey = DateTime(vnTime.year, vnTime.month, vnTime.day);

      final isAssessed = item['isAssessed'] as bool? ?? false;
      final podNum = (item['podNumber'] as int? ?? 0).clamp(0, 7);
      final triageStr = (item['triageColor'] as String? ?? 'GREEN').toUpperCase();
      final triageColor = triageStr == 'RED'
          ? TriageColor.red
          : triageStr == 'YELLOW'
          ? TriageColor.yellow
          : TriageColor.green;

      final detailsRaw = item['details'] as List<dynamic>? ?? [];
      final source = (item['source'] as String? ?? 'SURVEY').toUpperCase();
      final nurseNote = (item['nurseNote'] ?? item['nurse_note']) as String?;
      final isReassessment = source == 'REASSESSMENT' || source == 'NOTE' || (detailsRaw.isEmpty && isAssessed);

      List<SymptomHistoryDetail> symptoms = detailsRaw.map((d) {
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
          resultBadge: d['optionText'] as String? ?? '',
          status: severity,
          icon: _getIconForQuestion(d['questionId'] as int? ?? 0),
        );
      }).toList();

      if (isReassessment && symptoms.isEmpty) {
        final label = triageStr == 'GREEN'
            ? 'Ổn định'
            : triageStr == 'YELLOW'
            ? 'Cần theo dõi'
            : 'Nguy cấp';
        final status = triageStr == 'GREEN'
            ? SymptomSeverityStatus.green
            : triageStr == 'YELLOW'
            ? SymptomSeverityStatus.yellow
            : SymptomSeverityStatus.red;
        final noteText = (nurseNote != null && nurseNote.trim().isNotEmpty)
            ? 'Ghi chú điều dưỡng: ${nurseNote.trim()}'
            : 'Bài đánh giá này được thực hiện bởi điều dưỡng trong quá trình theo dõi lâm sàng.';

        symptoms = [
          SymptomHistoryDetail(
            questionId: 999,
            symptomName: 'Được đánh giá lại bởi điều dưỡng',
            shortDescription: noteText,
            resultBadge: label,
            status: status,
            icon: Icons.rate_review_rounded,
          ),
        ];
      }

      final log = AssessmentHistoryLog(
        assessmentId: item['assessmentId'] as int?,
        date: vnTime,
        podNumber: podNum,
        isAssessed: isAssessed,
        isReassessment: isReassessment,
        nurseNote: nurseNote,
        triageColor: triageColor,
        recoveryStatusTag: item['recoveryStatusTag'] as String? ??
            (isReassessment
                ? 'Đã đánh giá lại'
                : (isAssessed ? 'Hồi phục tốt' : 'Chưa đánh giá')),
        completedCount: item['completedCount'] as int? ?? (isAssessed ? 5 : 0),
        totalCount: item['totalCount'] as int? ?? 5,
        symptoms: symptoms,
        medicalFeedback: item['medicalFeedback'] as String?,
      );

      map.putIfAbsent(dayKey, () => []).add(log);
      podMap[dayKey] = podNum;
    }
  }

  // Sort dates ascending (oldest on left, newest/latest on right)
  final sortedDates = map.keys.toList()..sort();
  return sortedDates.map((date) {
    final logs = map[date]!;
    logs.sort((a, b) => a.date.compareTo(b.date));
    return PatientHistoryDayGroup(
      date: date,
      podNumber: podMap[date] ?? 0,
      logs: logs,
    );
  }).toList();
});

/// Resolves currently active DayGroup matching selected date or defaulting to latest
final activeHistoryDayGroupProvider = Provider<PatientHistoryDayGroup?>((ref) {
  final dayGroups = ref.watch(patientDayGroupsProvider);
  if (dayGroups.isEmpty) return null;

  final selectedDate = ref.watch(selectedHistoryDateProvider);
  if (selectedDate != null) {
    return dayGroups.firstWhere(
      (g) => isSameDay(g.date, selectedDate),
      orElse: () => dayGroups.last,
    );
  }

  // Default behavior aligned with Nurse / Doctor detail page:
  // If an assessed group exists for today, select today; otherwise default to dayGroups.last.
  final now = DateTime.now();
  final vnNow = _toVietnamTime(now);
  final todayKey = DateTime(vnNow.year, vnNow.month, vnNow.day);

  final matchToday = dayGroups.firstWhere(
    (g) => isSameDay(g.date, todayKey) && g.isAssessed,
    orElse: () => dayGroups.last,
  );

  return matchToday;
});

/// Resolves currently active assessment log for display
final activeAssessmentLogProvider = Provider<AssessmentHistoryLog?>((ref) {
  final group = ref.watch(activeHistoryDayGroupProvider);
  if (group == null || group.logs.isEmpty) return null;

  final selectedAssessmentId = ref.watch(selectedAssessmentIdProvider);
  if (selectedAssessmentId != null) {
    return group.logs.firstWhere(
      (l) => l.assessmentId == selectedAssessmentId,
      orElse: () => group.latestLog,
    );
  }

  return group.latestLog;
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
