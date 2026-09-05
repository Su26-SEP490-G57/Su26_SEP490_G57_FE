import 'package:poms/features/nurse/domain/models/patient_summary.dart';

/// Repository contract for doctor patient access.
abstract class DoctorPatientRepository {
  /// Returns ALL patients in the system (no room-assignment filter).
  Future<List<PatientSummary>> getAllPatients({
    String? search,
    String? level,
    int page,
    int limit,
  });
}
