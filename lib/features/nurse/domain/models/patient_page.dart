import 'package:poms/features/nurse/domain/models/patient_summary.dart';

class PatientPage {
  const PatientPage({
    required this.patients,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PatientSummary> patients;
  final int total;
  final int page;
  final int limit;
}
