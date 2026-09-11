class AssessmentDetail {
  const AssessmentDetail({
    required this.assessmentId,
    required this.caseId,
    required this.evaluationDateTime,
    required this.podContext,
    required this.totalScore,
    required this.triageColor,
    required this.details,
    this.source = 'SURVEY',
    this.nurseNote,
  });

  final int assessmentId;
  final String caseId;
  final DateTime evaluationDateTime;
  final int podContext;
  final int totalScore;
  final String triageColor;
  final List<AssessmentDetailItem> details;
  final String source;
  final String? nurseNote;
}

class AssessmentDetailItem {
  const AssessmentDetailItem({
    required this.questionId,
    required this.questionText,
    required this.selectedOptionId,
    required this.optionText,
    required this.scoreEarned,
  });

  final int questionId;
  final String questionText;
  final int selectedOptionId;
  final String optionText;
  final int scoreEarned;
}
