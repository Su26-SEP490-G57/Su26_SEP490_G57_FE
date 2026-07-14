import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/diet_guidance_remote_datasource.dart';
import '../../data/repositories/diet_guidance_repository_impl.dart';
import '../../domain/models/pod_protocol_model.dart';
import '../../domain/repositories/diet_guidance_repository.dart';

// Providers for Data Layer
final dietGuidanceRemoteDataSourceProvider = Provider<DietGuidanceRemoteDataSource>((ref) {
  final dio = ref.watch(appDioProvider);
  return DietGuidanceRemoteDataSource(dio);
});

final dietGuidanceRepositoryProvider = Provider<DietGuidanceRepository>((ref) {
  final remoteDataSource = ref.watch(dietGuidanceRemoteDataSourceProvider);
  return DietGuidanceRepositoryImpl(remoteDataSource);
});

// Provider for fetching current diet guidance
final currentDietGuidanceProvider = FutureProvider.autoDispose<PodProtocolModel?>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  
  if (user == null || user.caseId == null) {
    throw Exception('User is not logged in or does not have a case assigned.');
  }

  final repository = ref.watch(dietGuidanceRepositoryProvider);
  return await repository.getCurrentDietGuidance(user.caseId!);
});
