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
  });

  final String caseId;
  final bool viewedGuidance;
  final bool viewedEducation;
  final int reminderCount;
  final int appAccessCount;
  final int assessmentCompletedCount;
  final bool isCompliant;
}
