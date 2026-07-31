import 'package:flutter/material.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';

enum SymptomSeverityStatus {
  green,
  yellow,
  red,
}

extension SymptomSeverityStatusX on SymptomSeverityStatus {
  Color get badgeBgColor => switch (this) {
        SymptomSeverityStatus.green => const Color(0xFFE6F9F1),
        SymptomSeverityStatus.yellow => const Color(0xFFFFF7E6),
        SymptomSeverityStatus.red => const Color(0xFFFEE2E2),
      };

  Color get badgeTextColor => switch (this) {
        SymptomSeverityStatus.green => const Color(0xFF10B981),
        SymptomSeverityStatus.yellow => const Color(0xFFF59E0B),
        SymptomSeverityStatus.red => const Color(0xFFEF4444),
      };

  Color get iconBgColor => switch (this) {
        SymptomSeverityStatus.green => const Color(0xFFE6F9F1),
        SymptomSeverityStatus.yellow => const Color(0xFFFFF7E6),
        SymptomSeverityStatus.red => const Color(0xFFFEE2E2),
      };
}

class SymptomHistoryDetail {
  const SymptomHistoryDetail({
    required this.questionId,
    required this.symptomName,
    required this.shortDescription,
    required this.resultBadge,
    required this.status,
    required this.icon,
  });

  final int questionId;
  final String symptomName;
  final String shortDescription;
  final String resultBadge;
  final SymptomSeverityStatus status;
  final IconData icon;
}

class AssessmentHistoryLog {
  const AssessmentHistoryLog({
    required this.date,
    required this.podNumber,
    required this.isAssessed,
    required this.triageColor,
    required this.recoveryStatusTag,
    required this.completedCount,
    required this.totalCount,
    this.symptoms = const [],
    this.medicalFeedback,
  });

  final DateTime date;
  final int podNumber;
  final bool isAssessed;
  final TriageColor triageColor;
  final String recoveryStatusTag;
  final int completedCount;
  final int totalCount;
  final List<SymptomHistoryDetail> symptoms;
  final String? medicalFeedback;

  int get completionPercentage =>
      totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;
}
