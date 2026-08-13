import 'package:dio/dio.dart';

import 'package:poms/features/patient/domain/models/current_pod.dart';
import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';

class DietGuidanceRemoteDataSource {
  const DietGuidanceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PodProtocolModel>> getPodProtocols(int operationTypeId) async {
    final response = await _dio.get(
      '/diet-guidance/operation-types/$operationTypeId/pods',
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PodProtocolModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PodProtocolModel> getPodProtocolDetail(
    int operationTypeId,
    int podId,
  ) async {
    final response = await _dio.get(
      '/diet-guidance/operation-types/$operationTypeId/pods/$podId',
    );
    return PodProtocolModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CurrentPod> getCurrentPod(String caseId) async {
    // Endpoint: GET /patients/:id/current-pod
    // Wait, the backend uses `id` as `case_id` for this specific endpoint.
    final response = await _dio.get('/patients/$caseId/current-pod');
    return CurrentPod.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPatientByCaseId(String caseId) async {
    // Endpoint: GET /patients?search={caseId}
    final response = await _dio.get(
      '/patients',
      queryParameters: {'search': caseId},
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>;
    if (items.isEmpty) {
      throw Exception('Patient not found');
    }
    return items.first as Map<String, dynamic>;
  }

  Future<PodProtocolModel?> getCurrentDietGuidance(String caseId) async {
    final response = await _dio.get(
      '/diet-guidance/patient/$caseId/current',
    );
    if (response.data == null || response.data == '') {
      return null;
    }
    return PodProtocolModel.fromJson(response.data as Map<String, dynamic>);
  }
}

