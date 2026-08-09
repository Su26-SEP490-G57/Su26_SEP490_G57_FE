import 'package:dio/dio.dart';
import 'package:poms/features/nurse/data/models/assessment_response.dart';
import 'package:poms/features/nurse/data/models/assessment_detail_response.dart';

class AssessmentRemoteDataSource {
  AssessmentRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AssessmentResponse> getLatestAssessment(String caseId) async {
    final response = await _dio.get('/symptom-surveys/$caseId/latest');

    return AssessmentResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssessmentDetailResponse> getAssessmentDetail(int assessmentId) async {
    final response = await _dio.get('/symptom-surveys/$assessmentId');

    return AssessmentDetailResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AssessmentHistoryResponse> getAssessmentHistory(
    String caseId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/patients/$caseId/assessments',
      queryParameters: {'page': page, 'limit': limit},
    );

    return AssessmentHistoryResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
