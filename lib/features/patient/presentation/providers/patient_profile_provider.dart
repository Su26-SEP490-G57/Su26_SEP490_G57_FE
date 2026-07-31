import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/presentation/providers/diet_guidance_provider.dart';

final patientProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  final caseId = user?.caseId;

  if (caseId == null || caseId.isEmpty) {
    return null;
  }

  final remoteDataSource = ref.watch(dietGuidanceRemoteDataSourceProvider);
  return await remoteDataSource.getPatientByCaseId(caseId);
});
