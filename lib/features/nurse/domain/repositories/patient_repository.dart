import 'package:poms/features/nurse/domain/models/patient_page.dart';

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
}
