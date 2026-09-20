import 'package:poms/features/nurse/domain/models/alert_model.dart';
import 'package:poms/features/nurse/domain/repositories/alert_repository.dart';
import 'package:poms/features/nurse/data/datasources/alert_remote_datasource.dart';

class AlertRepositoryImpl implements AlertRepository {
  const AlertRepositoryImpl(this._remoteDataSource);

  final AlertRemoteDataSource _remoteDataSource;

  @override
  Future<List<AlertModel>> getActiveAlerts() async {
    // Fetch all alerts in one call — server no longer accepts status filter.
    // Client-side deduplication (keep latest per caseId) is done in
    // AlertsNotifier.load(), so no further filtering needed here.
    final alerts = await _remoteDataSource.getAlerts(limit: 100);

    // Sort by triggeredAt descending.
    alerts.sort((a, b) {
      final dateA = a.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return alerts;
  }
}
