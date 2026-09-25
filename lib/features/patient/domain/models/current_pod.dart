import 'package:equatable/equatable.dart';

class CurrentPod extends Equatable {
  const CurrentPod({
    required this.caseId,
    required this.isLocked,
    this.currentPod,
    this.holdReason,
    this.triageColor,
    this.isAssessmentLocked = false,
    this.erasCompleted = false,
    this.canSubmitAssessment = true,
    this.assessmentDisabledReason,
  });

  factory CurrentPod.fromJson(Map<String, dynamic> json) {
    return CurrentPod(
      caseId: json['caseId'] as String,
      currentPod: json['currentPod'] as int?,
      isLocked: json['isLocked'] as bool? ?? false,
      holdReason: json['holdReason'] as String?,
      triageColor: json['triageColor'] as String?,
      isAssessmentLocked: json['isAssessmentLocked'] as bool? ?? false,
      erasCompleted: json['erasCompleted'] as bool? ?? false,
      canSubmitAssessment: json['canSubmitAssessment'] as bool? ?? true,
      assessmentDisabledReason: json['assessmentDisabledReason'] as String?,
    );
  }

  final String caseId;
  final int? currentPod;
  final bool isLocked;
  final String? holdReason;
  final String? triageColor;
  final bool isAssessmentLocked;
  final bool erasCompleted;
  final bool canSubmitAssessment;
  final String? assessmentDisabledReason;

  @override
  List<Object?> get props => [
        caseId,
        currentPod,
        isLocked,
        holdReason,
        triageColor,
        isAssessmentLocked,
        erasCompleted,
        canSubmitAssessment,
        assessmentDisabledReason,
      ];
}
