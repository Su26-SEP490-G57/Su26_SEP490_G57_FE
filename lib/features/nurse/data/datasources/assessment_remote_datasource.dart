import 'package:dio/dio.dart';
import '../models/assessment_response.dart';
import '../models/assessment_detail_response.dart';

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
}
