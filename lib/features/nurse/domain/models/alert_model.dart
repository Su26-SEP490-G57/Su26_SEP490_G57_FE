import 'package:equatable/equatable.dart';

class AlertModel extends Equatable {
  const AlertModel({
    required this.alertId,
    required this.caseId,
    required this.assessmentId,
    required this.alertType,
    required this.status,
    this.surveyScore,
    this.isAutoProgression,
    this.triggeredAt,
    this.nurseAction,
    this.nursingNote,
    this.closedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alertId'] as int,
      caseId: json['caseId'] as String,
      assessmentId: json['assessmentId'] as int,
      surveyScore: json['surveyScore'] as int?,
      alertType: json['alertType'] as String,
      status: json['status'] as String,
      isAutoProgression: json['isAutoProgression'] as bool?,
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.tryParse(json['triggeredAt'] as String)
          : null,
      nurseAction: json['nurseAction'] as String?,
      nursingNote: json['nursingNote'] as String?,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'] as String)
          : null,
    );
  }

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

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'caseId': caseId,
    'assessmentId': assessmentId,
    'surveyScore': surveyScore,
    'alertType': alertType,
    'status': status,
    'isAutoProgression': isAutoProgression,
    'triggeredAt': triggeredAt?.toIso8601String(),
    'nurseAction': nurseAction,
    'nursingNote': nursingNote,
    'closedAt': closedAt?.toIso8601String(),
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
