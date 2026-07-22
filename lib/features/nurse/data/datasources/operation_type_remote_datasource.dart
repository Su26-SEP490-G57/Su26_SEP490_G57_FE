import 'package:dio/dio.dart';
import 'package:poms/features/nurse/data/models/operation_type_response.dart';

abstract interface class OperationTypeRemoteDatasource {
  Future<List<OperationTypeResponse>> getOperationTypes();
}

class OperationTypeRemoteDatasourceImpl
    implements OperationTypeRemoteDatasource {
  OperationTypeRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<OperationTypeResponse>> getOperationTypes() async {
    final response = await _dio.get('/patients/operation-types');

    return (response.data as List)
        .map((e) => OperationTypeResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
