import 'package:poms/features/nurse/data/datasources/treatment_order_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';
import 'package:poms/features/nurse/domain/repositories/treatment_order_repository.dart';

class TreatmentOrderRepositoryImpl implements TreatmentOrderRepository {
  TreatmentOrderRepositoryImpl(this._dataSource);

  final TreatmentOrderRemoteDataSource _dataSource;

  @override
  Future<List<TreatmentOrder>> getHistory(String caseId) {
    return _dataSource.getHistory(caseId);
  }

  @override
  Future<TreatmentOrder> createOrder({
    required String caseId,
    required CareLevel careLevel,
    String? instructions,
  }) {
    return _dataSource.createOrder(
      caseId: caseId,
      careLevel: careLevel,
      instructions: instructions,
    );
  }
}
