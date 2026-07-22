class AssessmentSummary {
  const AssessmentSummary({
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
}
