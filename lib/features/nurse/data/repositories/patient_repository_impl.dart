import 'package:poms/features/nurse/data/datasources/patient_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/patient_page.dart';
import 'package:poms/features/nurse/domain/repositories/patient_repository.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._remote);

  final PatientRemoteDataSource _remote;

  @override
  Future<PatientPage> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _remote.getPatients(
      search: search,
      level: level,
      operationTypeId: operationTypeId,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      limit: limit,
    );

    return PatientPage(
      patients: response.data.map((patient) {
        return PatientSummary(
          code: patient.caseId,
          name: patient.account.fullName,
          room: patient.roomBed ?? 'Chưa cập nhật',
          pod: 'POD ${patient.currentPod}',
          status: _mapStatus(patient.level),

          age: patient.age,
          gender: patient.gender,
          bmi: patient.bmi,

          surgeryDate: patient.surgeryDate,
          surgeryType: patient.operationType?.name,

          diagnosis: patient.diagnosis,
          operationTypeId: patient.operationType?.id,
          operationTypeName: patient.operationType?.name,
          operationMethod: patient.method,
          hasGiAnastomosis: patient.hasGiAnastomosis,
        );
      }).toList(),
      total: response.total,
      page: response.page,
      limit: response.limit,
    );
  }

  PatientStatus _mapStatus(dynamic level) {
    if (level == null) {
      return PatientStatus.green;
    }

    final name = level['name']?.toString().toLowerCase();

    switch (name) {
      case 'red':
        return PatientStatus.red;

      case 'yellow':
        return PatientStatus.yellow;

      default:
        return PatientStatus.green;
    }
  }
}
