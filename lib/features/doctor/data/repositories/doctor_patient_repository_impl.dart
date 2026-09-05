import 'package:poms/features/doctor/data/datasources/doctor_patient_remote_datasource.dart';
import 'package:poms/features/doctor/domain/repositories/doctor_patient_repository.dart';
import 'package:poms/features/nurse/data/models/patient_response.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

class DoctorPatientRepositoryImpl implements DoctorPatientRepository {
  DoctorPatientRepositoryImpl(this._remote);

  final DoctorPatientRemoteDataSource _remote;

  @override
  Future<List<PatientSummary>> getAllPatients({
    String? search,
    String? level,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _remote.getAllPatients(
      search: search,
      level: level,
      page: page,
      limit: limit,
    );
    return response.data.map(_toSummary).toList();
  }

  PatientSummary _toSummary(PatientResponse r) {
    PatientStatus status;
    final levelStr = r.level?.toString().toUpperCase() ?? '';
    if (levelStr.contains('RED') || levelStr == '3') {
      status = PatientStatus.red;
    } else if (levelStr.contains('YELLOW') || levelStr == '2') {
      status = PatientStatus.yellow;
    } else {
      status = PatientStatus.green;
    }

    return PatientSummary(
      code: r.caseId,
      name: r.account.fullName,
      room: r.roomBed ?? 'Chưa cập nhật',
      pod: 'POD ${r.currentPod}',
      status: status,
      age: r.age,
      gender: r.gender,
      bmi: r.bmi,
      surgeryDate: r.surgeryDate,
      surgeryType: r.operationType?.name,
      diagnosis: r.diagnosis,
      operationTypeId: r.operationType?.id,
      operationTypeName: r.operationType?.name,
      operationMethod: r.method,
      hasGiAnastomosis: r.hasGiAnastomosis,
    );
  }
}
