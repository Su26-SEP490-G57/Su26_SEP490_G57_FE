import '../../domain/models/assessment_summary.dart';

class AssessmentResponse {
  const AssessmentResponse({
    required this.assessmentId,
    required this.caseId,
    required this.evaluationDateTime,
    required this.podContext,
    required this.totalScore,
    required this.triageColor,
  });

  final int assessmentId;
  final String caseId;
  final DateTime evaluationDateTime;
  final int podContext;
  final int totalScore;
  final String triageColor;

  factory AssessmentResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentResponse(
      assessmentId: json['assessment_id'] as int,
      caseId: json['case_id'] as String,
      evaluationDateTime: DateTime.parse(
        json['evaluation_datetime'] as String,
      ),
      podContext: json['pod_context'] as int,
      totalScore: json['total_score'] as int,
      triageColor: json['triage_color'] as String,
    );
  }

  AssessmentSummary toDomain() {
    return AssessmentSummary(
      assessmentId: assessmentId,
      caseId: caseId,
      evaluationDateTime: evaluationDateTime,
      podContext: podContext,
      totalScore: totalScore,
      triageColor: triageColor,
    );
  }
}