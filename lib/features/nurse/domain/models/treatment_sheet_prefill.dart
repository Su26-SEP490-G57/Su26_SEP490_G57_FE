import 'package:poms/features/nurse/domain/models/care_level.dart';

/// Các trường "Phiếu theo dõi điều trị" được máy chủ tự điền
/// (`GET /treatment-orders/patient/:caseId/sheet-prefill`).
///
/// Phần hành chính chỉ để hiển thị — khi lưu, máy chủ tự lấy lại từ hồ sơ.
class TreatmentSheetPrefill {
  const TreatmentSheetPrefill({
    required this.sheetNumber,
    required this.facility,
    required this.department,
    required this.caseId,
    required this.patientName,
    required this.diagnosisOptions,
    required this.comorbidities,
    required this.progressNotes,
    this.age,
    this.gender,
    this.room,
    this.bed,
    this.diagnosis,
    this.latestVitalSignAt,
    this.activeCareLevel,
  });

  factory TreatmentSheetPrefill.fromJson(Map<String, dynamic> json) {
    return TreatmentSheetPrefill(
      sheetNumber: (json['sheetNumber'] as num?)?.toInt() ?? 1,
      facility: json['facility'] as String? ?? '',
      department: json['department'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      room: json['room'] as String?,
      bed: json['bed'] as String?,
      diagnosis: json['diagnosis'] as String?,
      diagnosisOptions:
          (json['diagnosisOptions'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      comorbidities:
          (json['comorbidities'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      progressNotes: json['progressNotes'] as String? ?? '',
      latestVitalSignAt: DateTime.tryParse(
        '${json['latestVitalSignAt'] ?? ''}',
      ),
      activeCareLevel: CareLevelX.fromBackend(json['activeCareLevel']),
    );
  }

  final int sheetNumber;
  final String facility;
  final String department;
  final String caseId;
  final String patientName;
  final int? age;
  final String? gender;
  final String? room;
  final String? bed;
  final String? diagnosis;
  final List<String> diagnosisOptions;

  /// "Bệnh kèm theo" — nhãn ICD `CODE - Tên` như form thêm người bệnh.
  final List<String> comorbidities;

  /// "Diễn biến bệnh" seed từ chỉ số sinh tồn gần nhất ('' nếu chưa có).
  final String progressNotes;
  final DateTime? latestVitalSignAt;
  final CareLevel? activeCareLevel;
}

/// Phần bác sĩ nhập của phiếu. "Chỉ định" đi riêng dưới dạng `instructions`.
class TreatmentSheetInput {
  const TreatmentSheetInput({
    required this.recordedAt,
    required this.progressNotes,
    this.diagnosis,
    this.comorbidities = const [],
  });

  final DateTime recordedAt;
  final String progressNotes;
  final String? diagnosis;

  /// Luôn gửi (kể cả rỗng) — danh sách rỗng nghĩa là bác sĩ đã xoá hết.
  final List<String> comorbidities;

  Map<String, dynamic> toJson() => {
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'progressNotes': progressNotes,
    if (diagnosis != null && diagnosis!.isNotEmpty) 'diagnosis': diagnosis,
    'comorbidities': comorbidities,
  };
}
