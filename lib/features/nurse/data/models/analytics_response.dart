class ComplianceOverviewResponse {
  const ComplianceOverviewResponse({
    required this.compliant,
    required this.nonCompliant,
    required this.complianceRate,
  });

  factory ComplianceOverviewResponse.fromJson(Map<String, dynamic> json) {
    return ComplianceOverviewResponse(
      compliant: json['compliant'] as int? ?? 0,
      nonCompliant: json['nonCompliant'] as int? ?? 0,
      complianceRate: (json['complianceRate'] as num?)?.toDouble() ?? 0,
    );
  }

  final int compliant;
  final int nonCompliant;
  final double complianceRate;
}

class AnalyticsOverviewResponse {
  const AnalyticsOverviewResponse({required this.compliance});

  factory AnalyticsOverviewResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverviewResponse(
      compliance: ComplianceOverviewResponse.fromJson(
        json['compliance'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final ComplianceOverviewResponse compliance;
}

class PatientComplianceResponse {
  const PatientComplianceResponse({
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

  factory PatientComplianceResponse.fromJson(Map<String, dynamic> json) {
    return PatientComplianceResponse(
      caseId: json['caseId'] as String,
      viewedGuidance: json['viewedGuidance'] as bool? ?? false,
      viewedEducation: json['viewedEducation'] as bool? ?? false,
      reminderCount: json['reminderCount'] as int? ?? 0,
      appAccessCount: json['appAccessCount'] as int? ?? 0,
      assessmentCompletedCount: json['assessmentCompletedCount'] as int? ?? 0,
      isCompliant: json['isCompliant'] as bool? ?? false,
      morningAssessmentStatus: json['morningAssessmentStatus'] as String?,
      afternoonAssessmentStatus: json['afternoonAssessmentStatus'] as String?,
      isDailyCompliant: json['isDailyCompliant'] as bool? ?? false,
    );
  }

  final String caseId;
  final bool viewedGuidance;
  final bool viewedEducation;
  final int reminderCount;
  final int appAccessCount;
  final int assessmentCompletedCount;
  final bool isCompliant;
  final String? morningAssessmentStatus;
  final String? afternoonAssessmentStatus;
  final bool isDailyCompliant;
}

class AssessmentMatrixCellResponse {
  const AssessmentMatrixCellResponse({required this.pod, required this.score});

  factory AssessmentMatrixCellResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentMatrixCellResponse(
      pod: json['pod'] as int,
      score: json['score'] as int?,
    );
  }

  final int pod;
  final int? score;
}

class AssessmentMatrixQuestionResponse {
  const AssessmentMatrixQuestionResponse({
    required this.questionId,
    required this.questionText,
    required this.orderNumber,
    required this.cells,
  });

  factory AssessmentMatrixQuestionResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentMatrixQuestionResponse(
      questionId: json['questionId'] as int,
      questionText: json['questionText'] as String? ?? '',
      orderNumber: json['orderNumber'] as int?,
      cells: (json['cells'] as List<dynamic>? ?? [])
          .map(
            (e) => AssessmentMatrixCellResponse.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final int questionId;
  final String questionText;
  final int? orderNumber;
  final List<AssessmentMatrixCellResponse> cells;
}

class AssessmentMatrixResponse {
  const AssessmentMatrixResponse({
    required this.caseId,
    required this.pods,
    required this.questions,
  });

  factory AssessmentMatrixResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentMatrixResponse(
      caseId: json['caseId'] as String,
      pods: (json['pods'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      questions:
          (json['questions'] as List<dynamic>? ?? [])
              .map(
                (e) => AssessmentMatrixQuestionResponse.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList()
            ..sort(
              (a, b) => (a.orderNumber ?? a.questionId).compareTo(
                b.orderNumber ?? b.questionId,
              ),
            ),
    );
  }

  final String caseId;
  final List<int> pods;
  final List<AssessmentMatrixQuestionResponse> questions;
}
