import 'package:equatable/equatable.dart';

class CurrentPod extends Equatable {
  const CurrentPod({
    required this.caseId,
    required this.isLocked,
    this.currentPod,
    this.holdReason,
  });

  factory CurrentPod.fromJson(Map<String, dynamic> json) {
    return CurrentPod(
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

  @override
  List<Object?> get props => [caseId, currentPod, isLocked, holdReason];
}
