import 'package:dio/dio.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';

class DoctorNotificationRemoteDataSource {
  const DoctorNotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AlertModel>> getHandledAlerts({
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/alerts/doctor-notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
