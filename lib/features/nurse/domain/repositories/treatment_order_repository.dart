import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';

abstract interface class TreatmentOrderRepository {
  Future<List<TreatmentOrder>> getHistory(String caseId);

  Future<TreatmentOrder> createOrder({
    required String caseId,
    required CareLevel careLevel,
    String? instructions,
  });
}
