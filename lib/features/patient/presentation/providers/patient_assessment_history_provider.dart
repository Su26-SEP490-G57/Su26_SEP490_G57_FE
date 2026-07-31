import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/patient/domain/models/symptom_history_model.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';

/// Single source of truth for the currently selected date in History Calendar
final selectedHistoryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// List of days displayed in the horizontal calendar selector
final historyCalendarDaysProvider = Provider<List<DateTime>>((ref) {
  final today = DateTime.now();
  final baseDate = DateTime(today.year, today.month, today.day);
  // Show 7 days window: from POD 0 (2 days ago) to POD 4 (4 days ahead)
  return List.generate(7, (index) => baseDate.add(Duration(days: index - 2)));
});

/// Query history assessment log for the selected date
final patientAssessmentHistoryProvider =
    Provider.family<AssessmentHistoryLog, DateTime>((ref, date) {
  final currentPodState = ref.watch(currentPodProvider).valueOrNull;
  final currentPodNum = currentPodState?.currentPod ?? 2;
  final today = DateTime.now();
  final baseToday = DateTime(today.year, today.month, today.day);

  // Calculate POD offset based on selected date relative to today
  final diffDays = date.difference(baseToday).inDays;
  final podForDate = currentPodNum + diffDays;

  // Mock / dynamic data logic per POD milestone
  if (podForDate == 2) {
    // Current POD 2 - Logged & Recovering well
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
    // POD 1 - Warning/Yellow triage
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
    // POD 0 - Day of surgery / Initial baseline
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
    // Future PODs or unassessed dates
    return AssessmentHistoryLog(
      date: date,
      podNumber: podForDate > 0 ? podForDate : 0,
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
