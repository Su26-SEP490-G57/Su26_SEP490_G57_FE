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
      assessmentId: json['assessmentId'] as int,
      caseId: json['caseId'] as String,
      evaluationDateTime: DateTime.parse(json['evaluationDatetime'] as String),
      podContext: json['podContext'] as int,
      totalScore: json['totalScore'] as int,
      triageColor: json['triageColor'] as String,
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
