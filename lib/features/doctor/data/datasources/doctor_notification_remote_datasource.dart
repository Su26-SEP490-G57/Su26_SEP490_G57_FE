import 'package:dio/dio.dart';
import 'package:poms/features/doctor/domain/models/doctor_notification.dart';

class DoctorNotificationRemoteDataSource {
  const DoctorNotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<DoctorNotification>> getNotifications({
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/patients/nurse-pause-logs',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .where(DoctorNotification.isVisible)
        .map(DoctorNotification.fromJson)
        .toList();
  }
}
