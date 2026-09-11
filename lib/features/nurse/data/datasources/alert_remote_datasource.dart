import 'package:dio/dio.dart';

import 'package:poms/features/nurse/domain/models/alert_model.dart';

class AlertRemoteDataSource {
  const AlertRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AlertModel>> getAlerts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) {
      queryParameters['status'] = status;
    }

    final response = await _dio.get(
      '/alerts',
      queryParameters: queryParameters,
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy alert PENDING_REVIEW mới nhất của một bệnh nhân (theo caseId).
  Future<AlertModel?> getActiveAlertByCaseId(String caseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/alerts',
        queryParameters: {
          'caseId': caseId,
          'status': 'PENDING_REVIEW',
          'page': 1,
          'limit': 1,
        },
      );
      final data = response.data?['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;
      return AlertModel.fromJson(data.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Xác nhận đã hoàn thành xử trí alert (PENDING_REVIEW → HANDLED).
  Future<AlertModel> acknowledgeAlert({
    required int alertId,
    String? nurseAction,
    String? nursingNote,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/alerts/$alertId/acknowledge',
      data: {
        if (nurseAction != null && nurseAction.isNotEmpty)
          'nurseAction': nurseAction,
        if (nursingNote != null && nursingNote.isNotEmpty)
          'nursingNote': nursingNote,
      },
    );
    return AlertModel.fromJson(response.data!);
  }
}
