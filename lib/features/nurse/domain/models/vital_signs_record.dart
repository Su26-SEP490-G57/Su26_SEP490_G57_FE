/// Một lần ghi nhận chỉ số sinh tồn.
///
/// `recordedByUserId` / `recordedByName` / `recordedAt` luôn do máy chủ sinh ra
/// — FE chỉ hiển thị, không bao giờ gửi lên hay cho phép chỉnh sửa.
class VitalSignsRecord {
  const VitalSignsRecord({
    required this.vitalSignId,
    required this.caseId,
    required this.pulseBpm,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.temperatureCelsius,
    required this.respiratoryRate,
    required this.spo2Percent,
    required this.recordedAt,
    this.note,
    this.recordedByUserId,
    this.recordedByName,
  });

  factory VitalSignsRecord.fromJson(Map<String, dynamic> json) {
    return VitalSignsRecord(
      vitalSignId: json['vitalSignId'] as int? ?? 0,
      caseId: json['caseId'] as String? ?? '',
      pulseBpm: (json['pulseBpm'] as num?)?.toInt() ?? 0,
      bloodPressureSystolic:
          (json['bloodPressureSystolic'] as num?)?.toInt() ?? 0,
      bloodPressureDiastolic:
          (json['bloodPressureDiastolic'] as num?)?.toInt() ?? 0,
      temperatureCelsius:
          double.tryParse('${json['temperatureCelsius'] ?? ''}') ?? 0,
      respiratoryRate: (json['respiratoryRate'] as num?)?.toInt() ?? 0,
      spo2Percent: (json['spo2Percent'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      recordedByUserId: (json['recordedByUserId'] as num?)?.toInt(),
      recordedByName: json['recordedByName'] as String?,
      recordedAt:
          DateTime.tryParse('${json['recordedAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  final int vitalSignId;
  final String caseId;
  final int pulseBpm;
  final int bloodPressureSystolic;
  final int bloodPressureDiastolic;
  final double temperatureCelsius;
  final int respiratoryRate;
  final int spo2Percent;
  final String? note;
  final int? recordedByUserId;
  final String? recordedByName;
  final DateTime recordedAt;

  String get bloodPressureLabel =>
      '$bloodPressureSystolic/$bloodPressureDiastolic';
}
