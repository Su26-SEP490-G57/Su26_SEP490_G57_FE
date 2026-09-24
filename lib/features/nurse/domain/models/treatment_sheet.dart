import 'package:poms/features/nurse/domain/models/care_level.dart';

/// "Phiếu theo dõi điều trị" đã lưu ở HIS
/// (`GET /treatment-orders/patient/:caseId/sheets`, mới nhất trước).
class TreatmentSheet {
  const TreatmentSheet({
    required this.sheetId,
    required this.sheetNumber,
    required this.patientCode,
    required this.patientName,
    required this.recordedAt,
    required this.progressNotes,
    required this.orders,
    required this.createdAt,
    this.facility,
    this.department,
    this.diagnosis,
    this.comorbidities,
    this.age,
    this.gender,
    this.room,
    this.bed,
    this.careLevel,
    this.doctorName,
  });

  factory TreatmentSheet.fromJson(Map<String, dynamic> json) {
    return TreatmentSheet(
      sheetId: (json['sheetId'] as num?)?.toInt() ?? 0,
      sheetNumber: (json['sheetNumber'] as num?)?.toInt() ?? 0,
      patientCode: json['patientCode'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      facility: json['facility'] as String?,
      department: json['department'] as String?,
      diagnosis: json['diagnosis'] as String?,
      comorbidities: json['comorbidities'] as String?,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      room: json['room'] as String?,
      bed: json['bed'] as String?,
      recordedAt:
          DateTime.tryParse('${json['recordedAt'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      progressNotes: json['progressNotes'] as String? ?? '',
      orders: json['orders'] as String? ?? '',
      careLevel: CareLevelX.fromBackend(json['careLevel']),
      doctorName: json['doctorName'] as String?,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal() ??
          DateTime.now(),
    );
  }

  final int sheetId;

  /// "Tờ số"
  final int sheetNumber;
  final String patientCode;
  final String patientName;
  final String? facility;
  final String? department;
  final String? diagnosis;
  final String? comorbidities;
  final int? age;
  final String? gender;
  final String? room;
  final String? bed;

  /// "Thời gian"
  final DateTime recordedAt;

  /// "Diễn biến bệnh"
  final String progressNotes;

  /// "Chỉ định"
  final String orders;
  final CareLevel? careLevel;
  final String? doctorName;
  final DateTime createdAt;
}
