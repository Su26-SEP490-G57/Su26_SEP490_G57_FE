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
      questionId: json['questionId'] as int,
      questionText: json['questionText'] as String,
      selectedOptionId: json['selectedOptionId'] as int,
      optionText: json['optionText'] as String,
      scoreEarned: json['scoreEarned'] as int,
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
      assessmentId: json['assessmentId'] as int,
      caseId: json['caseId'] as String,
      evaluationDateTime: DateTime.parse(json['evaluationDatetime'] as String),
      podContext: json['podContext'] as int,
      totalScore: json['totalScore'] as int,
      triageColor: json['triageColor'] as String,
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
