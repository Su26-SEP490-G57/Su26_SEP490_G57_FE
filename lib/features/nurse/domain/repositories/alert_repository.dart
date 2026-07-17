import 'package:poms/features/nurse/domain/models/alert_model.dart';

abstract class AlertRepository {
  Future<List<AlertModel>> getActiveAlerts();
}
