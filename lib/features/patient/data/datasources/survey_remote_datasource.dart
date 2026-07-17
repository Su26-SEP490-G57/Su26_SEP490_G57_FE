import 'package:dio/dio.dart';

import 'package:poms/core/errors/app_exception.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';

class SurveyRemoteDataSource {
  SurveyRemoteDataSource(this._dio);

  final Dio _dio;

  static const _baseEndpoint = '/symptom-surveys';

  Future<List<SurveyQuestion>> getQuestions() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '$_baseEndpoint/questions',
      );
      final data = response.data;
      if (data == null) throw const ServerException(statusCode: 500);
      return data
          .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurveySubmitResult> submitSurvey(SurveySubmitRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _baseEndpoint,
        data: request.toJson(),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException(statusCode: 500);
      }
      return SurveySubmitResult.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurveySubmitResult> getSurveyById(int surveyId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseEndpoint/$surveyId',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException(statusCode: 500);
      }
      return SurveySubmitResult.fromJson(data);
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
          message: message ?? 'Server error',
        );
      default:
        throw NetworkException(message ?? 'Error $statusCode');
    }
  }
}
