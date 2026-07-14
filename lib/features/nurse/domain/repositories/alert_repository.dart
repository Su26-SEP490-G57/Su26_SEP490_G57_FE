import '../models/alert_model.dart';

abstract class AlertRepository {
  Future<List<AlertModel>> getActiveAlerts();
}
