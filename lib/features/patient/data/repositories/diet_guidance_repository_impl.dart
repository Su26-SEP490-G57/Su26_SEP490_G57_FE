import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';
import 'package:poms/features/patient/domain/repositories/diet_guidance_repository.dart';
import 'package:poms/features/patient/data/datasources/diet_guidance_remote_datasource.dart';

class DietGuidanceRepositoryImpl implements DietGuidanceRepository {
  const DietGuidanceRepositoryImpl(this._remoteDataSource);

  final DietGuidanceRemoteDataSource _remoteDataSource;

  @override
  Future<PodProtocolModel?> getCurrentDietGuidance(String caseId) async {
    try {
      final guidance = await _remoteDataSource.getCurrentDietGuidance(caseId);
      if (guidance != null) {
        return guidance;
      }
    } catch (_) {
      // Fallback below if endpoint fails
    }

    try {
      // Fallback: 1. Get Patient Details to get operationTypeId and currentDietLevel
      final patientDetail = await _remoteDataSource.getPatientByCaseId(caseId);
      final operationType =
          patientDetail['operationType'] as Map<String, dynamic>?;

      if (operationType == null) {
        return null;
      }

      final operationTypeId = operationType['id'] as int;
      final dietLevel = patientDetail['currentDietLevel'] as int? ?? 0;

      // 2. Get all Pod Protocols for this operation type
      final podProtocols = await _remoteDataSource.getPodProtocols(
        operationTypeId,
      );

      // 3. Match protocol by dietLevel
      return podProtocols.firstWhere(
        (p) => p.dietLevel == dietLevel,
        orElse: () => podProtocols.first,
      );
    } catch (_) {
      return null;
    }
  }
}
