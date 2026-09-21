/// A notification shown in the doctor's inbox.
///
/// Records are sourced from `GET /patients/nurse-pause-logs`. The API already
/// restricts results to manual `Nurse_Pause` audit logs, excluding System_Auto.
class DoctorNotification {
  const DoctorNotification({
    required this.id,
    required this.caseId,
    required this.createdAt,
    this.patientName,
    this.roomBed,
    this.reason,
    this.actorName,
  });

  factory DoctorNotification.fromJson(Map<String, dynamic> json) {
    final caseId = (json['caseId'] ?? '').toString();
    final createdAt = _parseDateTime(json['changedAt'] ?? json['createdAt']);

    return DoctorNotification(
      id:
          (json['logId'] ??
                  json['notificationId'] ??
                  '$caseId-${createdAt?.microsecondsSinceEpoch ?? 0}')
              .toString(),
      caseId: caseId,
      createdAt: createdAt,
      patientName: json['patientName'] as String?,
      roomBed: json['roomBed'] as String?,
      reason:
          (json['holdReason'] ?? json['reason'] ?? json['nursingNote'])
              as String?,
      actorName: (json['nurseName'] ?? json['actorName']) as String?,
    );
  }

  /// Whether this record is allowed in the doctor's notification inbox.
  ///
  /// Reject anything that isn't an audit log and keep a defensive exclusion
  /// for System_Auto if that field is present in a future API response.
  static bool isVisible(Map<String, dynamic> json) {
    final actionType = (json['actionType'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    return json['logId'] != null && actionType != 'SYSTEM_AUTO';
  }

  final String id;
  final String caseId;
  final DateTime? createdAt;
  final String? patientName;
  final String? roomBed;
  final String? reason;
  final String? actorName;

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
