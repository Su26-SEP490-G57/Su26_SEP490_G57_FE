/// Mức chăm sóc (care level) do bác sĩ chỉ định — tách biệt hoàn toàn với
/// `PatientStatus` (phân loại ĐỎ/VÀNG/XANH của ERAS triage).
///
/// Backend dùng enum chuỗi `LEVEL_1` / `LEVEL_2` / `LEVEL_3`; trong FE ta lưu
/// dưới dạng số nguyên 1/2/3 (`PatientSummary.careLevel`) và chỉ quy đổi ở
/// ranh giới datasource.
enum CareLevel { level1, level2, level3 }

extension CareLevelX on CareLevel {
  int get value => switch (this) {
    CareLevel.level1 => 1,
    CareLevel.level2 => 2,
    CareLevel.level3 => 3,
  };

  String get backendValue => switch (this) {
    CareLevel.level1 => 'LEVEL_1',
    CareLevel.level2 => 'LEVEL_2',
    CareLevel.level3 => 'LEVEL_3',
  };

  String get label => 'Cấp $value';

  String get description => switch (this) {
    CareLevel.level1 => 'Chăm sóc cấp I — theo dõi sát',
    CareLevel.level2 => 'Chăm sóc cấp II — theo dõi trung bình',
    CareLevel.level3 => 'Chăm sóc cấp III — theo dõi cơ bản',
  };

  static CareLevel? fromBackend(Object? value) {
    return switch (value) {
      'LEVEL_1' => CareLevel.level1,
      'LEVEL_2' => CareLevel.level2,
      'LEVEL_3' => CareLevel.level3,
      _ => null,
    };
  }

  static CareLevel? fromValue(int? value) {
    return switch (value) {
      1 => CareLevel.level1,
      2 => CareLevel.level2,
      3 => CareLevel.level3,
      _ => null,
    };
  }

  /// Nhãn hiển thị cho một mức chăm sóc đã lưu dạng số (có thể null).
  static String labelOf(int? value) {
    final level = fromValue(value);
    return level == null ? 'Chưa chỉ định' : level.label;
  }
}
