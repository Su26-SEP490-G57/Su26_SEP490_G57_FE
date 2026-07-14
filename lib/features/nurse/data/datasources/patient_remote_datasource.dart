import 'package:dio/dio.dart';

class PatientRemoteDataSource {
  final Dio _dio;

  PatientRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (level != null && level.isNotEmpty) queryParams['level'] = level;
    if (operationTypeId != null) queryParams['operationTypeId'] = operationTypeId;
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

    final response = await _dio.get(
      '/patients',
      queryParameters: queryParams,
    );

    return response.data as Map<String, dynamic>;
  }
}
