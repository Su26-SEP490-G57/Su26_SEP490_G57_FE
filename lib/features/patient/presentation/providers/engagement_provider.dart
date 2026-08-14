import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/data/datasources/engagement_remote_datasource.dart';
import 'package:poms/features/patient/data/repositories/engagement_repository_impl.dart';
import 'package:poms/features/patient/domain/repositories/engagement_repository.dart';

final engagementRemoteDataSourceProvider = Provider<EngagementRemoteDataSource>(
  (ref) {
    return EngagementRemoteDataSource(ref.watch(appDioProvider));
  },
);

final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return EngagementRepositoryImpl(
    ref.watch(engagementRemoteDataSourceProvider),
  );
});
