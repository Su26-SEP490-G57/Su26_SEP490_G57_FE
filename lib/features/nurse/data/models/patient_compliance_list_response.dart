class PatientComplianceItemResponse {
  const PatientComplianceItemResponse({
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

  factory PatientComplianceItemResponse.fromJson(Map<String, dynamic> json) {
    return PatientComplianceItemResponse(
      caseId: json['caseId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roomBed: json['roomBed'] as String?,
      currentPod: json['currentPod'] as int?,
      level: (json['level'] as Map<String, dynamic>?)?['id'] as int?,
      levelName: (json['level'] as Map<String, dynamic>?)?['name'] as String?,
      viewedGuidance: json['viewedGuidance'] as bool? ?? false,
      viewedEducation: json['viewedEducation'] as bool? ?? false,
      morningAssessmentStatus: json['morningAssessmentStatus'] as String?,
      afternoonAssessmentStatus: json['afternoonAssessmentStatus'] as String?,
      complianceRate: (json['complianceRate'] as num?)?.toDouble() ?? 0,
      isCompliant: json['isCompliant'] as bool? ?? false,
      isDailyCompliant: json['isDailyCompliant'] as bool? ?? false,
    );
  }

  final String caseId;
  final String fullName;
  final String? roomBed;
  final int? currentPod;
  final int? level;
  final String? levelName;
  final bool viewedGuidance;
  final bool viewedEducation;
  final String? morningAssessmentStatus;
  final String? afternoonAssessmentStatus;
  final double complianceRate;
  final bool isCompliant;
  final bool isDailyCompliant;
}

class PatientComplianceListResponse {
  const PatientComplianceListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PatientComplianceListResponse.fromJson(Map<String, dynamic> json) {
    return PatientComplianceListResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map(
            (e) => PatientComplianceItemResponse.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }

  final List<PatientComplianceItemResponse> data;
  final int total;
  final int page;
  final int limit;
}
