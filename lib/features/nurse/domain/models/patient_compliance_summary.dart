import 'package:poms/features/nurse/domain/models/patient_compliance.dart';

/// Tóm tắt tuân thủ của 1 bệnh nhân — dùng cho danh sách
/// "Người bệnh không tuân thủ" (GET /patients/analytics/compliance-list).
class PatientComplianceSummary {
  const PatientComplianceSummary({
    required this.caseId,
    required this.fullName,
    required this.roomBed,
    required this.currentPod,
    required this.level,
    required this.levelName,
    required this.viewedGuidance,
    required this.viewedEducation,
    required this.morningAssessmentStatus,
    required this.afternoonAssessmentStatus,
    required this.complianceRate,
    required this.isCompliant,
    required this.isDailyCompliant,
  });

  factory PatientComplianceSummary.fromJson(Map<String, dynamic> json) {
    return PatientComplianceSummary(
      caseId: json['caseId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roomBed: json['roomBed'] as String?,
      currentPod: json['currentPod'] as int?,
      level: (json['level'] as Map<String, dynamic>?)?['id'] as int?,
      levelName: (json['level'] as Map<String, dynamic>?)?['name'] as String?,
      viewedGuidance: json['viewedGuidance'] as bool? ?? false,
      viewedEducation: json['viewedEducation'] as bool? ?? false,
      morningAssessmentStatus: ScheduledAssessmentStatus.fromApi(
        json['morningAssessmentStatus'] as String?,
      ),
      afternoonAssessmentStatus: ScheduledAssessmentStatus.fromApi(
        json['afternoonAssessmentStatus'] as String?,
      ),
      complianceRate: (json['complianceRate'] as num?)?.toDouble() ?? 0,
      isCompliant: json['isCompliant'] as bool? ?? false,
      isDailyCompliant: json['isDailyCompliant'] as bool? ?? false,
    );
  }

  final String caseId;
  final String fullName;
  final String? roomBed;

  /// null khi bệnh nhân chưa bắt đầu ERAS (chưa có POD hiện tại).
  final int? currentPod;
  final int? level;
  final String? levelName;

  final bool viewedGuidance;
  final bool viewedEducation;

  /// null khi bệnh nhân chưa bắt đầu ERAS (chưa có POD hiện tại).
  final ScheduledAssessmentStatus? morningAssessmentStatus;
  final ScheduledAssessmentStatus? afternoonAssessmentStatus;

  final double complianceRate;
  final bool isCompliant;
  final bool isDailyCompliant;

  /// "POD 2" hoặc "—" khi chưa có POD.
  String get podLabel => currentPod != null ? 'POD $currentPod' : '—';
}
