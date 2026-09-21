import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/features/nurse/domain/models/vital_signs_record.dart';

class VitalSignsRemoteDataSource {
  VitalSignsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<VitalSignsRecord>> getHistory(
    String caseId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      AppConstants.endpointVitalSignsByPatient(caseId),
      queryParameters: {'page': page, 'limit': limit},
    );

    final raw = response.data;
    final list = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (list is! List) return const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(VitalSignsRecord.fromJson)
        .toList();
  }

  /// Máy chủ tự gán người ghi nhận và thời điểm ghi nhận — FE không gửi lên.
  Future<VitalSignsRecord> createVitalSigns({
    required String caseId,
    required int pulseBpm,
    required int bloodPressureSystolic,
    required int bloodPressureDiastolic,
    required double temperatureCelsius,
    required int respiratoryRate,
    required int spo2Percent,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.endpointVitalSigns,
      data: {
        'caseId': caseId,
        'pulseBpm': pulseBpm,
        'bloodPressureSystolic': bloodPressureSystolic,
        'bloodPressureDiastolic': bloodPressureDiastolic,
        'temperatureCelsius': temperatureCelsius,
        'respiratoryRate': respiratoryRate,
        'spo2Percent': spo2Percent,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return VitalSignsRecord.fromJson(data);
  }
}
