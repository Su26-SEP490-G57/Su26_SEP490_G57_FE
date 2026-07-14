import 'package:equatable/equatable.dart';

class AlertModel extends Equatable {
  const AlertModel({
    required this.alertId,
    required this.caseId,
    required this.assessmentId,
    this.surveyScore,
    required this.alertType,
    required this.status,
    this.isAutoProgression,
    this.triggeredAt,
    this.nurseAction,
    this.nursingNote,
    this.closedAt,
  });

  final int alertId;
  final String caseId;
  final int assessmentId;
  final int? surveyScore;
  final String alertType; // e.g., 'YELLOW', 'RED'
  final String status; // e.g., 'Pending', 'Acknowledged', 'Closed'
  final bool? isAutoProgression;
  final DateTime? triggeredAt;
  final String? nurseAction;
  final String? nursingNote;
  final DateTime? closedAt;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alert_id'] as int,
      caseId: json['case_id'] as String,
      assessmentId: json['assessment_id'] as int,
      surveyScore: json['survey_score'] as int?,
      alertType: json['alert_type'] as String,
      status: json['status'] as String,
      isAutoProgression: json['is_auto_progression'] as bool?,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.tryParse(json['triggered_at'] as String)
          : null,
      nurseAction: json['nurse_action'] as String?,
      nursingNote: json['nursing_note'] as String?,
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'alert_id': alertId,
        'case_id': caseId,
        'assessment_id': assessmentId,
        'survey_score': surveyScore,
        'alert_type': alertType,
        'status': status,
        'is_auto_progression': isAutoProgression,
        'triggered_at': triggeredAt?.toIso8601String(),
        'nurse_action': nurseAction,
        'nursing_note': nursingNote,
        'closed_at': closedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        alertId,
        caseId,
        assessmentId,
        surveyScore,
        alertType,
        status,
        isAutoProgression,
        triggeredAt,
        nurseAction,
        nursingNote,
        closedAt,
      ];
}
