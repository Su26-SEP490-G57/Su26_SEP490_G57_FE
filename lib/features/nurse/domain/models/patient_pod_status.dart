class PatientPodStatus {
  const PatientPodStatus({
    required this.caseId,
    required this.currentPod,
    required this.isLocked,
    required this.holdReason,
  });

  factory PatientPodStatus.fromJson(Map<String, dynamic> json) {
    return PatientPodStatus(
      caseId: json['caseId'] as String,
      currentPod: json['currentPod'] as int?,
      isLocked: json['isLocked'] as bool? ?? false,
      holdReason: json['holdReason'] as String?,
    );
  }

  final String caseId;
  final int? currentPod;
  final bool isLocked;
  final String? holdReason;
}
