import 'package:dio/dio.dart';
import 'package:poms/features/nurse/data/models/assessment_response.dart';
import 'package:poms/features/nurse/data/models/assessment_detail_response.dart';

class AssessmentRemoteDataSource {
  AssessmentRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AssessmentResponse> getLatestAssessment(String caseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/symptom-surveys/$caseId/latest',
    );
    final data = response.data;
    if (data == null) throw Exception('Empty response from server');
    return AssessmentResponse.fromJson(data);
  }

  Future<AssessmentDetailResponse> getAssessmentDetail(int assessmentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/symptom-surveys/$assessmentId',
    );
    final data = response.data;
    if (data == null) throw Exception('Empty response from server');
    return AssessmentDetailResponse.fromJson(data);
  }

  Future<AssessmentHistoryResponse> getAssessmentHistory(
    String caseId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/patients/$caseId/assessments',
      queryParameters: {'page': page, 'limit': limit},
    );

    final raw = response.data;
    return AssessmentHistoryResponse.fromRaw(raw);
  }
}
