import 'package:poms/features/nurse/domain/models/care_level.dart';

/// Nhóm cột của một mục trên phiếu giấy.
enum CareSheetGroup { observation, diagnosis, intervention }

CareSheetGroup _groupFromJson(Object? value) => switch (value) {
  'diagnosis' => CareSheetGroup.diagnosis,
  'intervention' => CareSheetGroup.intervention,
  _ => CareSheetGroup.observation,
};

class CareSheetField {
  const CareSheetField({
    required this.key,
    required this.label,
    this.multiline = false,
  });

  factory CareSheetField.fromJson(Map<String, dynamic> json) => CareSheetField(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    multiline: json['multiline'] as bool? ?? false,
  );

  final String key;
  final String label;
  final bool multiline;
}

class CareSheetSection {
  const CareSheetSection({
    required this.key,
    required this.title,
    required this.group,
    required this.fields,
  });

  factory CareSheetSection.fromJson(Map<String, dynamic> json) {
    return CareSheetSection(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      group: _groupFromJson(json['group']),
      fields:
          (json['fields'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CareSheetField.fromJson)
              .toList() ??
          const [],
    );
  }

  final String key;
  final String title;
  final CareSheetGroup group;
  final List<CareSheetField> fields;

  /// Khoá lưu trong `content` của phiếu: `section.field`.
  String contentKey(CareSheetField field) => '$key.${field.key}';
}

/// Bố cục "Phiếu theo dõi và chăm sóc" (MS 38/BV1) do máy chủ định nghĩa —
/// dùng chung cho Cấp 1 và Cấp 2-3, chỉ khác tiêu đề.
class CareSheetForm {
  const CareSheetForm({
    required this.formCode,
    required this.legend,
    required this.sections,
    required this.titles,
  });

  factory CareSheetForm.fromJson(Map<String, dynamic> json) {
    final titles = json['titles'];
    return CareSheetForm(
      formCode: json['formCode'] as String? ?? '',
      legend: json['legend'] as String? ?? '',
      sections:
          (json['sections'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CareSheetSection.fromJson)
              .toList() ??
          const [],
      titles: titles is Map<String, dynamic>
          ? titles.map((key, value) => MapEntry(key, '$value'))
          : const {},
    );
  }

  final String formCode;
  final String legend;
  final List<CareSheetSection> sections;
  final Map<String, String> titles;

  String titleOf(String? sheetType) =>
      titles[sheetType] ?? 'Phiếu theo dõi và chăm sóc';
}

Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map) return const {};
  return raw.map((key, value) => MapEntry('$key', '$value'));
}

/// Phiếu theo dõi và chăm sóc đã lưu ở HIS. Không sửa được sau khi lưu.
class CareSheet {
  const CareSheet({
    required this.sheetId,
    required this.sheetNumber,
    required this.sheetType,
    required this.patientCode,
    required this.patientName,
    required this.recordedAt,
    required this.content,
    required this.createdAt,
    this.careLevel,
    this.facility,
    this.department,
    this.admissionNumber,
    this.age,
    this.gender,
    this.room,
    this.bed,
    this.diagnosis,
    this.hasAllergy,
    this.allergyNote,
    this.nurseName,
  });

  factory CareSheet.fromJson(Map<String, dynamic> json) {
    return CareSheet(
      sheetId: (json['sheetId'] as num?)?.toInt() ?? 0,
      sheetNumber: (json['sheetNumber'] as num?)?.toInt() ?? 0,
      sheetType: json['sheetType'] as String? ?? '',
      careLevel: CareLevelX.fromBackend(json['careLevel']),
      patientCode: json['patientCode'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      facility: json['facility'] as String?,
      department: json['department'] as String?,
      admissionNumber: json['admissionNumber'] as String?,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      room: json['room'] as String?,
      bed: json['bed'] as String?,
      diagnosis: json['diagnosis'] as String?,
      hasAllergy: json['hasAllergy'] as bool?,
      allergyNote: json['allergyNote'] as String?,
      recordedAt:
          DateTime.tryParse('${json['recordedAt'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      content: _stringMap(json['content']),
      nurseName: json['nurseName'] as String?,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal() ??
          DateTime.now(),
    );
  }

  final int sheetId;

  /// "Tờ số"
  final int sheetNumber;

  /// 'LEVEL_1' (Cấp 1) | 'LEVEL_2_3' (Cấp 2-3)
  final String sheetType;
  final CareLevel? careLevel;
  final String patientCode;
  final String patientName;
  final String? facility;
  final String? department;

  /// "Số vào viện"
  final String? admissionNumber;
  final int? age;
  final String? gender;
  final String? room;
  final String? bed;
  final String? diagnosis;

  /// "Tiền sử dị ứng": true = có, false = chưa ghi nhận, null = không điền.
  final bool? hasAllergy;
  final String? allergyNote;

  /// "Ngày" + "Giờ"
  final DateTime recordedAt;
  final Map<String, String> content;

  /// "Tên điều dưỡng thực hiện"
  final String? nurseName;
  final DateTime createdAt;
}

/// Danh sách phiếu + bố cục để hiển thị `content`.
class CareSheetList {
  const CareSheetList({required this.sheets, required this.form});

  factory CareSheetList.fromJson(Map<String, dynamic> json) {
    return CareSheetList(
      sheets:
          (json['sheets'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CareSheet.fromJson)
              .toList() ??
          const [],
      form: CareSheetForm.fromJson(
        json['form'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final List<CareSheet> sheets;
  final CareSheetForm form;
}

/// Các trường phiếu chăm sóc được máy chủ tự điền.
class CareSheetPrefill {
  const CareSheetPrefill({
    required this.sheetNumber,
    required this.facility,
    required this.department,
    required this.caseId,
    required this.patientName,
    required this.nurseName,
    required this.content,
    required this.form,
    this.sheetType,
    this.careLevel,
    this.age,
    this.gender,
    this.room,
    this.bed,
    this.diagnosis,
    this.latestVitalSignAt,
  });

  factory CareSheetPrefill.fromJson(Map<String, dynamic> json) {
    return CareSheetPrefill(
      sheetType: json['sheetType'] as String?,
      careLevel: CareLevelX.fromBackend(json['careLevel']),
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
      nurseName: json['nurseName'] as String? ?? '',
      content: _stringMap(json['content']),
      latestVitalSignAt: DateTime.tryParse(
        '${json['latestVitalSignAt'] ?? ''}',
      ),
      form: CareSheetForm.fromJson(
        json['form'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  /// null = bác sĩ chưa chỉ định mức chăm sóc → chưa lập phiếu được.
  final String? sheetType;
  final CareLevel? careLevel;
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
  final String nurseName;

  /// Chỉ số sinh tồn gần nhất, cân nặng, BMI — điều dưỡng có thể sửa.
  final Map<String, String> content;
  final DateTime? latestVitalSignAt;
  final CareSheetForm form;
}

/// Phần điều dưỡng nhập khi lưu phiếu.
class CareSheetInput {
  const CareSheetInput({
    required this.recordedAt,
    required this.content,
    this.admissionNumber,
    this.hasAllergy,
    this.allergyNote,
  });

  final DateTime recordedAt;
  final Map<String, String> content;
  final String? admissionNumber;
  final bool? hasAllergy;
  final String? allergyNote;

  Map<String, dynamic> toJson() => {
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    if (admissionNumber != null && admissionNumber!.isNotEmpty)
      'admissionNumber': admissionNumber,
    if (hasAllergy != null) 'hasAllergy': hasAllergy,
    if (hasAllergy == true && allergyNote != null && allergyNote!.isNotEmpty)
      'allergyNote': allergyNote,
    'content': content,
  };
}
