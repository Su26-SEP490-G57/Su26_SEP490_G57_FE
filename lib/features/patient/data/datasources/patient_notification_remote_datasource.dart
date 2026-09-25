import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/features/patient/domain/models/patient_notification_model.dart';

class PatientNotificationRemoteDataSource {
  const PatientNotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PatientNotificationModel>> getMyNotifications() async {
    final response = await _dio.get(AppConstants.endpointMyNotifications);
    final data = response.data as List<dynamic>;
    return data
        .map(
          (e) => PatientNotificationModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> markAsRead(int notificationId) async {
    await _dio.patch(AppConstants.endpointMarkNotificationRead(notificationId));
  }
}
