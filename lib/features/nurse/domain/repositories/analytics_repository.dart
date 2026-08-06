import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';

abstract class AnalyticsRepository {
  Future<ComplianceOverview> getComplianceOverview();

  Future<PatientCompliance> getPatientCompliance(String caseId);

  Future<AssessmentMatrix> getAssessmentMatrix(String caseId);
}
