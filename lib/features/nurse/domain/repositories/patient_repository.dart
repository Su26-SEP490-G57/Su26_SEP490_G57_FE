import 'package:poms/features/nurse/domain/models/patient_page.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

abstract class PatientRepository {
  Future<PatientPage> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  });

  Future<void> connectRealtime();
  Future<void> disconnectRealtime();
  Stream<PatientSummary> createdPatients();
  Stream<PatientSummary> updatedPatients();
  Stream<String> deletedPatients();
}