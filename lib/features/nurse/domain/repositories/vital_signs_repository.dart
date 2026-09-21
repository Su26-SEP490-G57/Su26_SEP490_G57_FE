import 'package:poms/features/nurse/domain/models/vital_signs_record.dart';

abstract interface class VitalSignsRepository {
  Future<List<VitalSignsRecord>> getHistory(
    String caseId, {
    int page = 1,
    int limit = 20,
  });

  Future<VitalSignsRecord> createVitalSigns({
    required String caseId,
    required int pulseBpm,
    required int bloodPressureSystolic,
    required int bloodPressureDiastolic,
    required double temperatureCelsius,
    required int respiratoryRate,
    required int spo2Percent,
    String? note,
  });
}
