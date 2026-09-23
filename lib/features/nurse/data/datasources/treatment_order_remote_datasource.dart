import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet_prefill.dart';

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

  Future<List<TreatmentSheet>> getSheets(String caseId) async {
    final response = await _dio.get<dynamic>(
      AppConstants.endpointTreatmentSheetsByPatient(caseId),
    );

    final raw = response.data;
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(TreatmentSheet.fromJson)
        .toList();
  }

  Future<TreatmentSheetPrefill> getSheetPrefill(String caseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.endpointTreatmentSheetPrefill(caseId),
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return TreatmentSheetPrefill.fromJson(data);
  }

  /// `careLevel` được quy đổi sang chuỗi enum của backend tại đúng ranh giới
  /// datasource này — phần còn lại của FE chỉ làm việc với [CareLevel].
  /// `instructions` là ô "Chỉ định"; phiếu được máy chủ ghi sang HIS.
  Future<TreatmentOrder> createOrder({
    required String caseId,
    required CareLevel careLevel,
    required String instructions,
    required TreatmentSheetInput sheet,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.endpointTreatmentOrders,
      data: {
        'caseId': caseId,
        'careLevel': careLevel.backendValue,
        'instructions': instructions,
        'sheet': sheet.toJson(),
      },
    );

    final data = response.data;
    if (data == null) throw Exception('Empty response from server');

    return TreatmentOrder.fromJson(data);
  }
}
