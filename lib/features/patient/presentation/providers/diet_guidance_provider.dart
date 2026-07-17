import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/data/datasources/diet_guidance_remote_datasource.dart';
import 'package:poms/features/patient/data/repositories/diet_guidance_repository_impl.dart';
import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';
import 'package:poms/features/patient/domain/repositories/diet_guidance_repository.dart';

// Providers for Data Layer
final dietGuidanceRemoteDataSourceProvider =
    Provider<DietGuidanceRemoteDataSource>((ref) {
      final dio = ref.watch(appDioProvider);
      return DietGuidanceRemoteDataSource(dio);
    });

final dietGuidanceRepositoryProvider = Provider<DietGuidanceRepository>((ref) {
  final remoteDataSource = ref.watch(dietGuidanceRemoteDataSourceProvider);
  return DietGuidanceRepositoryImpl(remoteDataSource);
});

// Provider for fetching current diet guidance
final currentDietGuidanceProvider =
    FutureProvider.autoDispose<PodProtocolModel?>((ref) async {
      final user = ref.watch(authNotifierProvider).user;

      if (user == null || user.caseId == null) {
        throw Exception(
          'User is not logged in or does not have a case assigned.',
        );
      }

      final repository = ref.watch(dietGuidanceRepositoryProvider);
      return await repository.getCurrentDietGuidance(user.caseId!);
    });
