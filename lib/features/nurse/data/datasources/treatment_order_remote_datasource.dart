import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';

class TreatmentOrderRemoteDataSource {
  TreatmentOrderRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TreatmentOrder>> getHistory(String caseId) async {
    final response = await _dio.get<dynamic>(
      AppConstants.endpointTreatmentOrdersByPatient(caseId),
    );

    final raw = response.data;
    final list = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (list is! List) return const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(TreatmentOrder.fromJson)
        .toList();
  }

  /// `careLevel` được quy đổi sang chuỗi enum của backend tại đúng ranh giới
  /// datasource này — phần còn lại của FE chỉ làm việc với [CareLevel].
  Future<TreatmentOrder> createOrder({
    required String caseId,
    required CareLevel careLevel,
    String? instructions,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.endpointTreatmentOrders,
      data: {
        'caseId': caseId,
        'careLevel': careLevel.backendValue,
        if (instructions != null && instructions.isNotEmpty)
          'instructions': instructions,
      },
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return TreatmentOrder.fromJson(data);
  }
}
