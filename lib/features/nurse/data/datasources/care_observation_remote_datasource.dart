import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';

class CareObservationRemoteDataSource {
  CareObservationRemoteDataSource(this._dio);

  final Dio _dio;

  List<CareObservationTask> _toTasks(Object? raw) {
    final list = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (list is! List) return const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(CareObservationTask.fromJson)
        .toList();
  }

  /// Nhiệm vụ đang mở của chính điều dưỡng đang đăng nhập (máy chủ tự lọc theo
  /// danh sách người bệnh được phân công).
  Future<List<CareObservationTask>> getMyTasks() async {
    final response = await _dio.get<dynamic>(
      AppConstants.endpointCareObservationMyTasks,
    );

    return _toTasks(response.data);
  }

  /// Nhiệm vụ hiện tại + bảng kiểm của một người bệnh. Trả về null nếu người
  /// bệnh chưa được chỉ định mức chăm sóc nào.
  Future<CareObservationTask?> getTaskForPatient(String caseId) async {
    final response = await _dio.get<dynamic>(
      AppConstants.endpointCareObservationTaskByPatient(caseId),
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is Map<String, dynamic>) {
        return CareObservationTask.fromJson(nested);
      }
      if (raw.isEmpty) return null;
      return CareObservationTask.fromJson(raw);
    }

    return null;
  }

  Future<CareObservationTask> getTaskDetail(int taskId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.endpointCareObservationTask(taskId),
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return CareObservationTask.fromJson(data);
  }

  /// Máy chủ tự gán người theo dõi và thời điểm theo dõi.
  Future<CareObservationEntry> submitEntry({
    required int taskId,
    required Map<String, String> findings,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.endpointCareObservationTaskEntries(taskId),
      data: {
        'findings': findings,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return CareObservationEntry.fromJson(data);
  }
}
