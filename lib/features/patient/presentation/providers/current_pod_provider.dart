import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/domain/models/current_pod.dart';
import 'package:poms/features/patient/presentation/providers/diet_guidance_provider.dart'; // To get the remote datasource provider

final currentPodProvider = FutureProvider.autoDispose<CurrentPod?>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  final caseId = user?.caseId;

  if (caseId == null || caseId.isEmpty) {
    return null;
  }

  // We reuse the existing remote data source which has `getCurrentPod`.
  // Ideally this would be in a generic patient_remote_datasource but we use the existing one to avoid redundant setups.
  final remoteDataSource = ref.watch(dietGuidanceRemoteDataSourceProvider);
  return await remoteDataSource.getCurrentPod(caseId);
});
