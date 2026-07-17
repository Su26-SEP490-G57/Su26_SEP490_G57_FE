import 'package:poms/features/nurse/domain/models/patient_summary.dart';

abstract class PatientRepository {
  Future<List<PatientSummary>> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  });
}
