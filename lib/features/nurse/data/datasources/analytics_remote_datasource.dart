import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/core/errors/app_exception.dart';
import 'package:poms/features/nurse/data/models/analytics_response.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AnalyticsOverviewResponse> getOverview() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.endpointAnalyticsOverview,
      );
      final data = response.data;
      if (data == null) throw const ServerException(statusCode: 500);
      return AnalyticsOverviewResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PatientComplianceResponse> getPatientCompliance(String caseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.endpointPatientCompliance(caseId),
      );
      final data = response.data;
      if (data == null) throw const ServerException(statusCode: 500);
      return PatientComplianceResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<AssessmentMatrixResponse> getAssessmentMatrix(String caseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.endpointAssessmentMatrix(caseId),
      );
      final data = response.data;
      if (data == null) throw const ServerException(statusCode: 500);
      return AssessmentMatrixResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Never _handleError(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    final message = data is Map<String, dynamic>
        ? data['message'] as String?
        : null;

    if (e.response == null) throw const NetworkException();

    switch (statusCode) {
      case 401:
        throw const UnauthorizedException();
      case 403:
        throw const ForbiddenException();
      case 404:
        throw const NotFoundException();
      case >= 500:
        throw ServerException(
          statusCode: statusCode,
          message: message ?? 'Lỗi hệ thống phía máy chủ ($statusCode)',
        );
      default:
        throw NetworkException(message ?? 'Đã xảy ra lỗi ($statusCode)');
    }
  }
}
