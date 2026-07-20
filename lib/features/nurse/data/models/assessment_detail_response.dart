import '../../domain/models/assessment_detail.dart';

class AssessmentDetailItemResponse {
  const AssessmentDetailItemResponse({
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

  factory AssessmentDetailItemResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentDetailItemResponse(
      questionId: json['question_id'] as int,
      questionText: json['question_text'] as String,
      selectedOptionId: json['selected_option_id'] as int,
      optionText: json['option_text'] as String,
      scoreEarned: json['score_earned'] as int,
    );
  }

  AssessmentDetailItem toDomain() {
    return AssessmentDetailItem(
      questionId: questionId,
      questionText: questionText,
      selectedOptionId: selectedOptionId,
      optionText: optionText,
      scoreEarned: scoreEarned,
    );
  }
}

class AssessmentDetailResponse {
  const AssessmentDetailResponse({
    required this.assessmentId,
    required this.caseId,
    required this.evaluationDateTime,
    required this.podContext,
    required this.totalScore,
    required this.triageColor,
    required this.details,
  });

  final int assessmentId;
  final String caseId;
  final DateTime evaluationDateTime;
  final int podContext;
  final int totalScore;
  final String triageColor;

  final List<AssessmentDetailItemResponse> details;

  factory AssessmentDetailResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentDetailResponse(
      assessmentId: json['assessment_id'] as int,
      caseId: json['case_id'] as String,
      evaluationDateTime: DateTime.parse(json['evaluation_datetime'] as String),
      podContext: json['pod_context'] as int,
      totalScore: json['total_score'] as int,
      triageColor: json['triage_color'] as String,
      details: (json['details'] as List<dynamic>)
          .map(
            (e) => AssessmentDetailItemResponse.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  AssessmentDetail toDomain() {
    return AssessmentDetail(
      assessmentId: assessmentId,
      caseId: caseId,
      evaluationDateTime: evaluationDateTime,
      podContext: podContext,
      totalScore: totalScore,
      triageColor: triageColor,
      details: details.map((e) => e.toDomain()).toList(),
    );
  }
}
