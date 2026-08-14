import 'package:dio/dio.dart';

import 'package:poms/core/errors/app_exception.dart';

class EngagementRemoteDataSource {
  EngagementRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> logEngagement(
    String caseId, {
    bool? viewedGuidance,
    bool? viewedEducation,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/patients/$caseId/engagement-logs',
        data: {
          'viewedGuidance': ?viewedGuidance,
          'viewedEducation': ?viewedEducation,
        },
      );
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
