import '../../domain/models/alert_model.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/alert_remote_datasource.dart';

class AlertRepositoryImpl implements AlertRepository {
  const AlertRepositoryImpl(this._remoteDataSource);

  final AlertRemoteDataSource _remoteDataSource;

  @override
  Future<List<AlertModel>> getActiveAlerts() async {
    // Typically, active alerts are 'Pending' or 'Acknowledged'. 
    // We can fetch all and filter, or make multiple calls if the BE requires exact matching.
    // For now, we'll fetch Pending and Acknowledged and combine them.
    final pendingAlerts = await _remoteDataSource.getAlerts(status: 'Pending', limit: 50);
    final ackAlerts = await _remoteDataSource.getAlerts(status: 'Acknowledged', limit: 50);

    final List<AlertModel> combined = [...pendingAlerts, ...ackAlerts];
    // Sort by triggeredAt descending
    combined.sort((a, b) {
      final dateA = a.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return combined;
  }
}
