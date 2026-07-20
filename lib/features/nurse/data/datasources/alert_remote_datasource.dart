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
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
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
}
