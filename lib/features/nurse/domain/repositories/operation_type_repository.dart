import 'package:poms/features/nurse/domain/models/operation_type.dart';

abstract interface class OperationTypeRepository {
  Future<List<OperationType>> getOperationTypes();
}
