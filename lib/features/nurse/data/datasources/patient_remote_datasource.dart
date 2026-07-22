import 'package:dio/dio.dart';
import 'package:poms/features/nurse/data/models/patient_response.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/core/errors/app_exception.dart';

class PatientRemoteDataSource {
  PatientRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PatientListResponse> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
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
    final statusCode = e.response?.statusCode ?? 0;
    final responseData = e.response?.data;
    final dataMap = responseData is Map<String, dynamic> ? responseData : null;

    final message =
        dataMap?['message'] as String? ?? dataMap?['error'] as String?;

    if (e.response == null) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const TimeoutException();
      }

      throw const NetworkException();
    }

    switch (statusCode) {
      case 400:
        throw NetworkException(message ?? 'Bad request');

      case 401:
        throw const UnauthorizedException();

      case 403:
        throw const ForbiddenException();

      case 404:
        throw const NotFoundException();

      default:
        if (statusCode >= 500) {
          throw ServerException(
            statusCode: statusCode,
            message: message ?? 'Server error',
          );
        }

        throw NetworkException(message ?? 'Unknown error ($statusCode)');
    }
  }
}
