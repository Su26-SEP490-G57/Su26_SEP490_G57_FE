import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/alert_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/alert_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';
import 'package:poms/features/nurse/domain/repositories/alert_repository.dart';

final alertRemoteDataSourceProvider = Provider<AlertRemoteDataSource>((ref) {
  final dio = ref.watch(appDioProvider);
  return AlertRemoteDataSource(dio);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final remoteDataSource = ref.watch(alertRemoteDataSourceProvider);
  return AlertRepositoryImpl(remoteDataSource);
});

final activeAlertsProvider = FutureProvider.autoDispose<List<AlertModel>>((
  ref,
) async {
  final repository = ref.watch(alertRepositoryProvider);
  return await repository.getActiveAlerts();
});
