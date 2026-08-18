/// Trạng thái của 1 khung giờ đánh giá định kỳ (sáng 06:00-08:00 / chiều 16:00-18:00).
enum ScheduledAssessmentStatus {
  completed,
  pending,
  missed;

  static ScheduledAssessmentStatus? fromApi(String? value) {
    switch (value) {
      case 'COMPLETED':
        return ScheduledAssessmentStatus.completed;
      case 'MISSED':
        return ScheduledAssessmentStatus.missed;
      case 'PENDING':
        return ScheduledAssessmentStatus.pending;
      default:
        return null;
    }
  }
}

/// Độ tuân thủ của 1 bệnh nhân — checklist + số liệu tương tác ứng dụng.
class PatientCompliance {
  const PatientCompliance({
    required this.caseId,
    required this.viewedGuidance,
    required this.viewedEducation,
    required this.reminderCount,
    required this.appAccessCount,
    required this.assessmentCompletedCount,
    required this.isCompliant,
    required this.morningAssessmentStatus,
    required this.afternoonAssessmentStatus,
    required this.isDailyCompliant,
  });

  final String caseId;
  final bool viewedGuidance;
  final bool viewedEducation;
  final int reminderCount;
  final int appAccessCount;
  final int assessmentCompletedCount;
  final bool isCompliant;

  /// null khi bệnh nhân chưa bắt đầu ERAS (chưa có POD hiện tại).
  final ScheduledAssessmentStatus? morningAssessmentStatus;
  final ScheduledAssessmentStatus? afternoonAssessmentStatus;

  /// Chỉ true khi đã xem hướng dẫn ăn + giáo dục sức khỏe + CẢ 2 khung giờ
  /// đánh giá định kỳ hôm nay đều Hoàn thành.
  final bool isDailyCompliant;
}
