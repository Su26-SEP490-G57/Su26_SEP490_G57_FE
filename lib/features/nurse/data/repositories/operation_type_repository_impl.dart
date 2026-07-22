import 'package:poms/features/nurse/domain/models/operation_type.dart';
import 'package:poms/features/nurse/domain/repositories/operation_type_repository.dart';
import 'package:poms/features/nurse/data/datasources/operation_type_remote_datasource.dart';

class OperationTypeRepositoryImpl implements OperationTypeRepository {
  OperationTypeRepositoryImpl(this._datasource);

  final OperationTypeRemoteDatasource _datasource;

  @override
  Future<List<OperationType>> getOperationTypes() async {
    final result = await _datasource.getOperationTypes();

    return result.map((e) => OperationType(id: e.id, name: e.name)).toList();
  }
}
