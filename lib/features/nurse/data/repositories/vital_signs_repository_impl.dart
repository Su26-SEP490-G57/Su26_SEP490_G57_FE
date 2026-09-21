import 'package:poms/features/nurse/data/datasources/vital_signs_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/vital_signs_record.dart';
import 'package:poms/features/nurse/domain/repositories/vital_signs_repository.dart';

class VitalSignsRepositoryImpl implements VitalSignsRepository {
  VitalSignsRepositoryImpl(this._dataSource);

  final VitalSignsRemoteDataSource _dataSource;

  @override
  Future<List<VitalSignsRecord>> getHistory(
    String caseId, {
    int page = 1,
    int limit = 20,
  }) {
    return _dataSource.getHistory(caseId, page: page, limit: limit);
  }

  @override
  Future<VitalSignsRecord> createVitalSigns({
    required String caseId,
    required int pulseBpm,
    required int bloodPressureSystolic,
    required int bloodPressureDiastolic,
    required double temperatureCelsius,
    required int respiratoryRate,
    required int spo2Percent,
    String? note,
  }) {
    return _dataSource.createVitalSigns(
      caseId: caseId,
      pulseBpm: pulseBpm,
      bloodPressureSystolic: bloodPressureSystolic,
      bloodPressureDiastolic: bloodPressureDiastolic,
      temperatureCelsius: temperatureCelsius,
      respiratoryRate: respiratoryRate,
      spo2Percent: spo2Percent,
      note: note,
    );
  }
}
