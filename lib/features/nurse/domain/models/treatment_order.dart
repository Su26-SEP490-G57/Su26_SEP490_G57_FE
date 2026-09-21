import 'package:poms/features/nurse/domain/models/care_level.dart';

/// Chỉ định điều trị do bác sĩ tạo. Thông tin người chỉ định và thời điểm
/// chỉ định luôn do máy chủ sinh ra.
class TreatmentOrder {
  const TreatmentOrder({
    required this.treatmentOrderId,
    required this.caseId,
    required this.careLevel,
    required this.orderedAt,
    this.instructions,
    this.orderedByUserId,
    this.orderedByName,
  });

  factory TreatmentOrder.fromJson(Map<String, dynamic> json) {
    return TreatmentOrder(
      treatmentOrderId: json['treatmentOrderId'] as int? ?? 0,
      caseId: json['caseId'] as String? ?? '',
      careLevel: CareLevelX.fromBackend(json['careLevel']),
      instructions: json['instructions'] as String?,
      orderedByUserId: (json['orderedByUserId'] as num?)?.toInt(),
      orderedByName: json['orderedByName'] as String?,
      orderedAt:
          DateTime.tryParse('${json['orderedAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  final int treatmentOrderId;
  final String caseId;
  final CareLevel? careLevel;
  final String? instructions;
  final int? orderedByUserId;
  final String? orderedByName;
  final DateTime orderedAt;
}
