import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';
import 'package:poms/features/patient/domain/repositories/diet_guidance_repository.dart';
import 'package:poms/features/patient/data/datasources/diet_guidance_remote_datasource.dart';

class DietGuidanceRepositoryImpl implements DietGuidanceRepository {
  const DietGuidanceRepositoryImpl(this._remoteDataSource);

  final DietGuidanceRemoteDataSource _remoteDataSource;

  @override
  Future<PodProtocolModel?> getCurrentDietGuidance(String caseId) async {
    // 1. Get Patient Details to get operationTypeId
    final patientDetail = await _remoteDataSource.getPatientByCaseId(caseId);
    final operationType =
        patientDetail['operationType'] as Map<String, dynamic>?;

    if (operationType == null) {
      throw Exception('Patient does not have an assigned operation type.');
    }

    final operationTypeId = operationType['id'] as int;

    final currentDietLevel = (patientDetail['currentDietLevel'] as int?) ?? 0;

    // 2. Get all Pod Protocols for this operation type
    final podProtocols = await _remoteDataSource.getPodProtocols(
      operationTypeId,
    );

    // 3. Find the protocol matching the patient's current diet level
    try {
      return podProtocols.firstWhere((p) => p.dietLevel == currentDietLevel);
    } catch (_) {
      if (podProtocols.isNotEmpty) {
        return podProtocols.first;
      }
      return null;
    }
  }
}
