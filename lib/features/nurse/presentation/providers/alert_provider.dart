import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/alert_remote_datasource.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../domain/models/alert_model.dart';
import '../../domain/repositories/alert_repository.dart';

final alertRemoteDataSourceProvider = Provider<AlertRemoteDataSource>((ref) {
  final dio = ref.watch(appDioProvider);
  return AlertRemoteDataSource(dio);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final remoteDataSource = ref.watch(alertRemoteDataSourceProvider);
  return AlertRepositoryImpl(remoteDataSource);
});

final activeAlertsProvider = FutureProvider.autoDispose<List<AlertModel>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return await repository.getActiveAlerts();
});
