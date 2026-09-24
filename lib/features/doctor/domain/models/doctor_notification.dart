/// A notification shown in the doctor's inbox.
///
/// Records sourced from nurse updates (vital signs updates, manual pause logs, etc.).
class DoctorNotification {
  const DoctorNotification({
    required this.id,
    required this.caseId,
    required this.createdAt,
    this.patientName,
    this.roomBed,
    this.reason,
    this.actorName,
    this.type = 'VITAL_SIGNS',
  });

  factory DoctorNotification.fromJson(Map<String, dynamic> json) {
    final caseId = (json['caseId'] ?? '').toString();
    final createdAt = _parseDateTime(json['changedAt'] ?? json['createdAt'] ?? json['recordedAt']);

    final pulse = json['pulseBpm'] ?? json['pulse'];
    final temp = json['temperatureCelsius'] ?? json['temperature'];
    final spo2 = json['spo2Percent'] ?? json['spo2'];

    String? vitalText;
    if (pulse != null || temp != null || spo2 != null) {
      final parts = <String>[];
      if (pulse != null) parts.add('Mạch: $pulse bpm');
      if (temp != null) parts.add('Nhiệt độ: $temp°C');
      if (spo2 != null) parts.add('SpO2: $spo2%');
      vitalText = parts.join(' • ');
    }

    final reasonRaw = (json['holdReason'] ?? json['reason'] ?? json['nursingNote'] ?? json['note']) as String?;

    String? displayReason = vitalText;
    if (vitalText != null && reasonRaw != null && reasonRaw.trim().isNotEmpty) {
      displayReason = '$vitalText • Ghi chú: ${reasonRaw.trim()}';
    } else {
      displayReason ??= reasonRaw;
    }

    return DoctorNotification(
      id: (json['logId'] ??
              json['notificationId'] ??
              json['vitalSignId'] ??
              '$caseId-${createdAt?.microsecondsSinceEpoch ?? 0}')
          .toString(),
      caseId: caseId,
      createdAt: createdAt,
      patientName: json['patientName'] as String?,
      roomBed: json['roomBed'] as String?,
      reason: displayReason,
      actorName: (json['nurseName'] ?? json['actorName']) as String?,
      type: (vitalText != null || json['type'] == 'VITAL_SIGNS')
          ? 'VITAL_SIGNS'
          : 'NURSE_PAUSE',
    );
  }

  static bool isVisible(Map<String, dynamic> json) {
    final actionType = (json['actionType'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    return actionType != 'SYSTEM_AUTO';
  }

  final String id;
  final String caseId;
  final DateTime? createdAt;
  final String? patientName;
  final String? roomBed;
  final String? reason;
  final String? actorName;
  final String type;

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
