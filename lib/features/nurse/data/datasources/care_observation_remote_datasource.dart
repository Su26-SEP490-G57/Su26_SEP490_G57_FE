import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
import 'package:poms/features/nurse/domain/models/care_sheet.dart';

class CareObservationRemoteDataSource {
  CareObservationRemoteDataSource(this._dio);

  final Dio _dio;

  List<CareObservationTask> _toTasks(Object? raw) {
    final list = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (list is! List) return const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(CareObservationTask.fromJson)
        .toList();
  }

  /// Nhiệm vụ đang mở của chính điều dưỡng đang đăng nhập (máy chủ tự lọc theo
  /// danh sách người bệnh được phân công).
  Future<List<CareObservationTask>> getMyTasks() async {
    final response = await _dio.get<dynamic>(
      AppConstants.endpointCareObservationMyTasks,
    );

    return _toTasks(response.data);
  }

  /// Phiếu theo dõi và chăm sóc của một người bệnh (lưu ở HIS), mới nhất
  /// trước, kèm bố cục phiếu để hiển thị nội dung.
  Future<CareSheetList> getCareSheets(String caseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.endpointCareSheetsByPatient(caseId),
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return CareSheetList.fromJson(data);
  }

  Future<CareSheetPrefill> getCareSheetPrefill(String caseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.endpointCareSheetPrefill(caseId),
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return CareSheetPrefill.fromJson(data);
  }

  /// Phần hành chính, loại phiếu, phân cấp chăm sóc và điều dưỡng do máy chủ
  /// tự gán; phiếu được ghi sang HIS.
  Future<CareSheet> createCareSheet({
    required String caseId,
    required CareSheetInput sheet,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.endpointCareSheetsByPatient(caseId),
      data: sheet.toJson(),
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return CareSheet.fromJson(data);
  }

  /// File PDF của 1 phiếu (máy chủ dựng theo mẫu giấy).
  Future<Uint8List> getCareSheetPdf(String caseId, int sheetId) async {
    final response = await _dio.get<List<int>>(
      AppConstants.endpointCareSheetPdf(caseId, sheetId),
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) throw Exception('Empty response from server');
    return Uint8List.fromList(data);
  }
}
