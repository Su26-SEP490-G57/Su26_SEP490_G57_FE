/// Domain models cho assessment/survey feature
library;

// ─────────────────────────────────────────────────────────────────────────────
// GET /symptom-surveys/questions
// ─────────────────────────────────────────────────────────────────────────────

class SurveyOption {
  const SurveyOption({
    required this.optionId,
    required this.optionText,
    required this.scoreValue,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      optionId: json['option_id'] as int,
      optionText: json['option_text'] as String,
      scoreValue: json['score_value'] as int,
    );
  }

  final int optionId;
  final String optionText;
  final int scoreValue;
}

class SurveyQuestion {
  const SurveyQuestion({
    required this.questionId,
    required this.questionText,
    required this.orderNumber,
    required this.options,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      questionId: json['question_id'] as int,
      questionText: json['question_text'] as String,
      orderNumber: json['order_number'] as int,
      options: (json['options'] as List<dynamic>)
          .map((o) => SurveyOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  final int questionId;
  final String questionText;
  final int orderNumber;
  final List<SurveyOption> options;
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /symptom-surveys
// ─────────────────────────────────────────────────────────────────────────────

class SurveyAnswer {
  const SurveyAnswer({
    required this.questionId,
    required this.selectedOptionId,
  });

  final int questionId;
  final int selectedOptionId;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_option_id': selectedOptionId,
  };
}

class SurveySubmitRequest {
  const SurveySubmitRequest({
    required this.caseId,
    required this.answers,
    this.podContext,
    this.shiftPeriod,
  });

  final String caseId;
  final List<SurveyAnswer> answers;
  final int? podContext;
  final String? shiftPeriod;

  Map<String, dynamic> toJson() => {
    'case_id': caseId,
    'answers': answers.map((a) => a.toJson()).toList(),
    if (podContext != null) 'pod_context': podContext,
    if (shiftPeriod != null) 'shift_period': shiftPeriod,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Response
// ─────────────────────────────────────────────────────────────────────────────

enum TriageColor { green, yellow, red }

extension TriageColorX on TriageColor {
  static TriageColor fromString(String value) {
    return switch (value.toUpperCase()) {
      'GREEN' => TriageColor.green,
      'YELLOW' => TriageColor.yellow,
      'RED' => TriageColor.red,
      _ => TriageColor.green,
    };
  }

  String get label => switch (this) {
    TriageColor.green => 'GREEN',
    TriageColor.yellow => 'YELLOW',
    TriageColor.red => 'RED',
  };
}

class SurveySubmitResult {
  const SurveySubmitResult({
    required this.assessmentId,
    required this.caseId,
    required this.totalScore,
    required this.triageColor,
    this.evaluationDatetime,
    this.recommendation,
  });

  factory SurveySubmitResult.fromJson(Map<String, dynamic> json) {
    return SurveySubmitResult(
      assessmentId: json['assessment_id'] as int,
      caseId: json['case_id'] as String,
      totalScore: json['total_score'] as int,
      triageColor: TriageColorX.fromString(
        json['triage_color'] as String? ?? 'GREEN',
      ),
      evaluationDatetime: json['evaluation_datetime'] as String?,
      recommendation: json['recommendation'] as String?,
    );
  }

  final int assessmentId;
  final String caseId;
  final int totalScore;
  final TriageColor triageColor;
  final String? evaluationDatetime;
  final String? recommendation;
}
