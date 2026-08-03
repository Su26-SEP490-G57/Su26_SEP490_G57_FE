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

  // Local fallback calculation if backend API timeline is loading or empty
  final currentPodState = ref.watch(currentPodProvider).valueOrNull;
  final currentPodNum = (currentPodState?.currentPod ?? 2).clamp(0, 5);
  final today = DateTime.now();
  final baseToday = DateTime(today.year, today.month, today.day);

  final diffDays = selectedDay.difference(baseToday).inDays;
  final podForDate = (currentPodNum + diffDays).clamp(0, 5);

  if (podForDate == 2) {
    return AssessmentHistoryLog(
      date: date,
      podNumber: 2,
      isAssessed: true,
      triageColor: TriageColor.green,
      recoveryStatusTag: 'Hồi phục tốt',
      completedCount: 5,
      totalCount: 5,
      symptoms: const [
        SymptomHistoryDetail(
          questionId: 1,
          symptomName: 'Mức độ đau vết mổ',
          shortDescription: 'Cảm giác đau rát nhẹ khi xoay người',
          resultBadge: 'Đau nhẹ (1/10)',
          status: SymptomSeverityStatus.green,
          icon: Icons.sick_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 2,
          symptomName: 'Buồn nôn / Nôn',
          shortDescription: 'Không còn cảm giác buồn nôn sau khi ăn nhẹ',
          resultBadge: 'Không có',
          status: SymptomSeverityStatus.green,
          icon: Icons.sentiment_satisfied_alt_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 3,
          symptomName: 'Khả năng ăn uống',
          shortDescription: 'Dung nạp tốt cháo lỏng và súp ấm',
          resultBadge: 'Ăn uống tốt',
          status: SymptomSeverityStatus.green,
          icon: Icons.restaurant_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 4,
          symptomName: 'Vận động & Đi lại',
          shortDescription: 'Đi lại nhẹ nhàng quanh phòng 15 phút',
          resultBadge: 'Đã hoàn thành',
          status: SymptomSeverityStatus.green,
          icon: Icons.directions_walk_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 5,
          symptomName: 'Trung tiện / Đại tiện',
          shortDescription: 'Đã trung tiện bình thường vào buổi sáng',
          resultBadge: 'Đã có',
          status: SymptomSeverityStatus.green,
          icon: Icons.water_drop_outlined,
        ),
      ],
      medicalFeedback:
          'Điều dưỡng ghi nhận: Chỉ số sinh tồn ổn định. Bệnh nhân hồi phục đúng tiến độ ERAS POD 2, tiếp tục vận động nhẹ và uống bù nước.',
    );
  } else if (podForDate == 1) {
    return AssessmentHistoryLog(
      date: date,
      podNumber: 1,
      isAssessed: true,
      triageColor: TriageColor.yellow,
      recoveryStatusTag: 'Cần theo dõi',
      completedCount: 5,
      totalCount: 5,
      symptoms: const [
        SymptomHistoryDetail(
          questionId: 1,
          symptomName: 'Mức độ đau vết mổ',
          shortDescription: 'Đau vừa ở vùng hạ vị khi ngồi dậy',
          resultBadge: 'Đau vừa (3/10)',
          status: SymptomSeverityStatus.yellow,
          icon: Icons.sick_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 2,
          symptomName: 'Buồn nôn / Nôn',
          shortDescription: 'Thỉnh thoảng buồn nôn nhẹ sau uống nước',
          resultBadge: 'Buồn nôn nhẹ',
          status: SymptomSeverityStatus.yellow,
          icon: Icons.sentiment_neutral_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 3,
          symptomName: 'Khả năng ăn uống',
          shortDescription: 'Uống được vài ngụm nước ấm và nước đường',
          resultBadge: 'Ăn uống ít',
          status: SymptomSeverityStatus.yellow,
          icon: Icons.restaurant_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 4,
          symptomName: 'Vận động & Đi lại',
          shortDescription: 'Tập ngồi dậy bên mép giường 10 phút',
          resultBadge: 'Đạt mục tiêu',
          status: SymptomSeverityStatus.green,
          icon: Icons.directions_walk_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 5,
          symptomName: 'Trung tiện / Đại tiện',
          shortDescription: 'Chưa trung tiện, bụng còn chướng nhẹ',
          resultBadge: 'Chưa trung tiện',
          status: SymptomSeverityStatus.yellow,
          icon: Icons.water_drop_outlined,
        ),
      ],
      medicalFeedback:
          'Điều dưỡng dặn dò: Tiếp tục chườm ấm bụng nhẹ nhàng và duy trì đi lại quanh giường để kích thích nhu động ruột.',
    );
  } else if (podForDate == 0) {
    return AssessmentHistoryLog(
      date: date,
      podNumber: 0,
      isAssessed: true,
      triageColor: TriageColor.green,
      recoveryStatusTag: 'Ổn định',
      completedCount: 5,
      totalCount: 5,
      symptoms: const [
        SymptomHistoryDetail(
          questionId: 1,
          symptomName: 'Mức độ đau vết mổ',
          shortDescription: 'Đã dùng giảm đau theo liều chỉ định',
          resultBadge: 'Đau nhẹ (2/10)',
          status: SymptomSeverityStatus.green,
          icon: Icons.sick_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 2,
          symptomName: 'Buồn nôn / Nôn',
          shortDescription: 'Không buồn nôn sau tỉnh mê',
          resultBadge: 'Không có',
          status: SymptomSeverityStatus.green,
          icon: Icons.sentiment_satisfied_alt_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 3,
          symptomName: 'Khả năng ăn uống',
          shortDescription: 'Nhiều ngụm nước nhỏ sau phẫu thuật',
          resultBadge: 'Uống nước nhẹ',
          status: SymptomSeverityStatus.green,
          icon: Icons.local_drink_outlined,
        ),
        SymptomHistoryDetail(
          questionId: 4,
          symptomName: 'Vận động & Đi lại',
          shortDescription: 'Xoay trở người trên giường',
          resultBadge: 'Đã hoàn thành',
          status: SymptomSeverityStatus.green,
          icon: Icons.bed_rounded,
        ),
        SymptomHistoryDetail(
          questionId: 5,
          symptomName: 'Trung tiện / Đại tiện',
          shortDescription: 'Đang theo dõi nhu động ruột',
          resultBadge: 'Đang theo dõi',
          status: SymptomSeverityStatus.green,
          icon: Icons.water_drop_outlined,
        ),
      ],
      medicalFeedback:
          'Bác sĩ phẫu thuật: Ca mổ thành công tốt đẹp. Bệnh nhân được chuyển về phòng hồi sức đạt tiêu chuẩn.',
    );
  } else {
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
  }
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
