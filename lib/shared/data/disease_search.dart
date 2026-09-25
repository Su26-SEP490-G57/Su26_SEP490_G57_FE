import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';

/// 1 mục trong danh mục mã bệnh ICD-10 (bảng `diseases` của backend, seed
/// trong migration CreateDiseasesTable). Lưu vào hồ sơ dưới dạng nhãn
/// `CODE - Tên` — giống hệt `DiseaseAutocomplete` trên web.
class DiseaseOption {
  const DiseaseOption({required this.code, required this.name});

  factory DiseaseOption.fromJson(Map<String, dynamic> json) =>
      DiseaseOption(code: json['code'] as String, name: json['name'] as String);

  final String code;
  final String name;

  String get label => '$code - $name';
}

/// Tìm theo mã hoặc tên (không dấu cũng được) — lọc phía server. Kết quả
/// được cache theo từ khoá vì danh mục gần như không đổi.
class DiseaseSearch {
  DiseaseSearch(this._dio);

  final Dio _dio;
  static final Map<String, List<DiseaseOption>> _cache = {};

  Future<List<DiseaseOption>> search(String query, {int limit = 20}) async {
    final key = query.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final response = await _dio.get<List<dynamic>>(
      AppConstants.endpointDiseases,
      queryParameters: {if (key.isNotEmpty) 'search': key, 'limit': limit},
    );
    final result = (response.data ?? [])
        .map((e) => DiseaseOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache[key] = result;
  }
}
