import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/core/errors/app_exception.dart';
import 'package:poms/features/nurse/data/models/patient_response.dart';

/// Remote data source for doctor — has access to ALL patients regardless of room assignment.
class DoctorPatientRemoteDataSource {
  DoctorPatientRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetches ALL patients (no room-filter applied).
  /// Doctors can see every patient in the system.
  Future<PatientListResponse> getAllPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.endpointPatients,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'level': ?level,
          'operationTypeId': ?operationTypeId,
          'sortBy': ?sortBy,
          'sortOrder': ?sortOrder,
          'page': page,
          'limit': limit,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException(
          statusCode: 500,
          message: 'Response body is null',
        );
      }

      return PatientListResponse.fromJson(body);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    throw ServerException(
      statusCode: e.response?.statusCode ?? 500,
      message: e.response?.data?['message']?.toString() ?? e.message ?? 'Unknown error',
    );
  }
}
