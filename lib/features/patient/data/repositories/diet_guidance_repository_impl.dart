import '../../domain/models/pod_protocol_model.dart';
import '../../domain/repositories/diet_guidance_repository.dart';
import '../datasources/diet_guidance_remote_datasource.dart';

class DietGuidanceRepositoryImpl implements DietGuidanceRepository {
  const DietGuidanceRepositoryImpl(this._remoteDataSource);

  final DietGuidanceRemoteDataSource _remoteDataSource;

  @override
  Future<PodProtocolModel?> getCurrentDietGuidance(String caseId) async {
    // 1. Get Patient Details to get operationTypeId
    final patientDetail = await _remoteDataSource.getPatientByCaseId(caseId);
    final operationType = patientDetail['operationType'] as Map<String, dynamic>?;
    
    if (operationType == null) {
      throw Exception('Patient does not have an assigned operation type.');
    }
    
    final operationTypeId = operationType['id'] as int;

    // 2. Get Current POD
    final podInfo = await _remoteDataSource.getCurrentPod(caseId);
    final currentPod = podInfo.currentPod;

    if (currentPod == null) {
      // Patient has not started ERAS or has no current POD
      return null;
    }

    // 3. Get all Pod Protocols for this operation type
    final podProtocols = await _remoteDataSource.getPodProtocols(operationTypeId);

    // 4. Find the matching protocol. The label could be 'POD 1' or just match the index/order if label is arbitrary.
    // However, POD labels usually follow 'POD X' or 'PODX'. We try to find a protocol whose label contains the current POD number.
    try {
      final matchingProtocol = podProtocols.firstWhere(
        (p) => p.label.toUpperCase().replaceAll(' ', '') == 'POD$currentPod',
      );
      return matchingProtocol;
    } catch (_) {
      // If exact match fails, fallback to checking if it just contains the number as a word
      try {
        final matchingProtocol = podProtocols.firstWhere(
          (p) => p.label.contains('$currentPod'),
        );
        return matchingProtocol;
      } catch (_) {
        return null; // No specific guidance for this POD day
      }
    }
  }
}
