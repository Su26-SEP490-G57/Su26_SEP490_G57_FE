import 'package:poms/features/nurse/domain/models/care_level.dart';

/// Một mục trong bảng kiểm (checklist) của phiếu theo dõi chăm sóc.
///
/// `inputType` do máy chủ quy định cách nhập liệu cho mục này
/// (`checkbox` / `number` / văn bản tự do nếu khác hoặc thiếu).
class CareObservationChecklistItem {
  const CareObservationChecklistItem({
    required this.key,
    required this.label,
    this.inputType = 'text',
  });

  factory CareObservationChecklistItem.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    return CareObservationChecklistItem(
      key: key,
      label: json['label'] as String? ?? key,
      inputType: json['inputType'] as String? ?? 'text',
    );
  }

  final String key;
  final String label;
  final String inputType;

  bool get isCheckbox => inputType == 'checkbox';
  bool get isNumber => inputType == 'number';
}

/// Một lần điền phiếu.
class CareObservationEntry {
  const CareObservationEntry({
    required this.entryId,
    required this.findings,
    required this.observedAt,
    this.note,
    this.observedByUserId,
    this.observedByName,
  });

  factory CareObservationEntry.fromJson(Map<String, dynamic> json) {
    final rawFindings = json['findings'];
    return CareObservationEntry(
      entryId: json['entryId'] as int? ?? 0,
      findings: rawFindings is Map
          ? rawFindings.map((k, v) => MapEntry('$k', '${v ?? ''}'))
          : const <String, String>{},
      note: json['note'] as String?,
      observedByUserId: (json['observedByUserId'] as num?)?.toInt(),
      observedByName: json['observedByName'] as String?,
      observedAt:
          DateTime.tryParse('${json['observedAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  final int entryId;
  final Map<String, String> findings;
  final String? note;
  final int? observedByUserId;
  final String? observedByName;
  final DateTime observedAt;
}

/// Nhiệm vụ theo dõi chăm sóc được gán cho điều dưỡng, kèm bảng kiểm của
/// phiếu tương ứng với mức chăm sóc bác sĩ đã chỉ định.
class CareObservationTask {
  const CareObservationTask({
    required this.taskId,
    required this.caseId,
    required this.status,
    this.patientName,
    this.templateCode,
    this.templateName,
    this.careLevelAtAssignment,
    this.checklistItems = const [],
    this.entries = const [],
    this.createdAt,
  });

  factory CareObservationTask.fromJson(Map<String, dynamic> json) {
    // Backend có thể lồng template vào `template` hoặc trải phẳng ra task.
    final template = json['template'] is Map<String, dynamic>
        ? json['template'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final rawItems =
        json['checklistItems'] ??
        template['checklistItems'] ??
        json['findings'];

    return CareObservationTask(
      taskId: json['taskId'] as int? ?? 0,
      caseId: json['caseId'] as String? ?? '',
      patientName:
          json['patientName'] as String? ??
          (json['patient'] is Map
              ? (json['patient'] as Map)['fullName'] as String?
              : null),
      templateCode:
          json['templateCode'] as String? ?? template['code'] as String?,
      templateName:
          json['templateName'] as String? ?? template['name'] as String?,
      careLevelAtAssignment: CareLevelX.fromBackend(
        json['careLevelAtAssignment'],
      ),
      status: json['status'] as String? ?? 'OPEN',
      checklistItems: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(CareObservationChecklistItem.fromJson)
                .toList()
          : const [],
      entries: json['entries'] is List
          ? (json['entries'] as List)
                .whereType<Map<String, dynamic>>()
                .map(CareObservationEntry.fromJson)
                .toList()
          : const [],
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  final int taskId;
  final String caseId;
  final String? patientName;
  final String? templateCode;
  final String? templateName;
  final CareLevel? careLevelAtAssignment;
  final String status;
  final List<CareObservationChecklistItem> checklistItems;
  final List<CareObservationEntry> entries;
  final DateTime? createdAt;

  /// Nhãn ngắn gọn cho loại phiếu.
  String get sheetLabel {
    if (templateName != null && templateName!.isNotEmpty) return templateName!;
    return switch (templateCode) {
      'LEVEL_1_SHEET' => 'Phiếu cấp 1',
      'LEVEL_2_3_SHEET' => 'Phiếu cấp 2-3',
      _ => 'Phiếu theo dõi',
    };
  }

  String get statusLabel => switch (status) {
    'OPEN' => 'Đang mở',
    'SUPERSEDED' => 'Đã thay thế',
    'COMPLETED' => 'Đã hoàn thành',
    _ => status,
  };
}
