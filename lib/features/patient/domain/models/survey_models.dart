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
      optionId: (json['optionId'] as int?) ?? (json['option_id'] as int? ?? 0),
      optionText:
          (json['optionText'] as String?) ??
          (json['option_text'] as String?) ??
          '',
      scoreValue:
          (json['scoreValue'] as int?) ?? (json['score_value'] as int? ?? 0),
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
    required this.isDefault,
    required this.options,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      questionId:
          (json['questionId'] as int?) ?? (json['question_id'] as int? ?? 0),
      questionText:
          (json['questionText'] as String?) ??
          (json['question_text'] as String?) ??
          '',
      orderNumber:
          (json['orderNumber'] as int?) ?? (json['order_number'] as int? ?? 0),
      isDefault: json['isDefault'] as bool? ?? false,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((o) => SurveyOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  final int questionId;
  final String questionText;
  final int orderNumber;
  final bool isDefault;
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
    'questionId': questionId,
    'selectedOptionId': selectedOptionId,
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
    'caseId': caseId,
    'answers': answers.map((a) => a.toJson()).toList(),
    if (podContext != null) 'podContext': podContext,
    if (shiftPeriod != null) 'shiftPeriod': shiftPeriod,
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
    TriageColor.green => 'Xanh',
    TriageColor.yellow => 'Vàng',
    TriageColor.red => 'Đỏ',
  };
}

class SurveyAnswerDetail {
  const SurveyAnswerDetail({
    required this.questionId,
    required this.questionText,
    required this.selectedOptionId,
    required this.optionText,
    required this.scoreEarned,
  });

  factory SurveyAnswerDetail.fromJson(Map<String, dynamic> json) {
    return SurveyAnswerDetail(
      questionId: json['questionId'] as int? ?? 0,
      questionText: json['questionText'] as String? ?? '',
      selectedOptionId: json['selectedOptionId'] as int? ?? 0,
      optionText: json['optionText'] as String? ?? '',
      scoreEarned: json['scoreEarned'] as int? ?? 0,
    );
  }

  final int questionId;
  final String questionText;
  final int selectedOptionId;
  final String optionText;
  final int scoreEarned;
}

class SurveySubmitResult {
  const SurveySubmitResult({
    required this.assessmentId,
    required this.caseId,
    required this.totalScore,
    required this.triageColor,
    this.evaluationDatetime,
    this.podContext,
    this.details = const [],
    this.recommendation,
  });

  factory SurveySubmitResult.fromJson(Map<String, dynamic> json) {
    return SurveySubmitResult(
      assessmentId: json['assessmentId'] as int? ?? 0,
      caseId: json['caseId'] as String? ?? '',
      totalScore: json['totalScore'] as int? ?? 0,
      triageColor: TriageColorX.fromString(
        json['triageColor'] as String? ?? 'GREEN',
      ),
      evaluationDatetime: json['evaluationDatetime'] as String?,
      podContext: json['podContext'] as int?,
      details: (json['details'] as List<dynamic>? ?? [])
          .map(
            (item) => SurveyAnswerDetail.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      recommendation: json['recommendation'] as String?,
    );
  }

  final int assessmentId;
  final String caseId;
  final int totalScore;
  final TriageColor triageColor;
  final String? evaluationDatetime;
  final int? podContext;
  final List<SurveyAnswerDetail> details;
  final String? recommendation;
}
