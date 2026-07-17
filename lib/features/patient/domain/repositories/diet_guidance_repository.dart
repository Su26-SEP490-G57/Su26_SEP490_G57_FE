import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';

abstract class DietGuidanceRepository {
  /// Fetches the current PodProtocol for the given caseId
  /// Returns null if no matching pod protocol is found for the patient's current POD.
  Future<PodProtocolModel?> getCurrentDietGuidance(String caseId);
}
