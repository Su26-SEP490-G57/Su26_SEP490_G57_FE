import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance_list_page.dart';

abstract class AnalyticsRepository {
  Future<ComplianceOverview> getComplianceOverview();

  Future<PatientCompliance> getPatientCompliance(String caseId);

  Future<AssessmentMatrix> getAssessmentMatrix(String caseId);

  Future<PatientComplianceListPage> getComplianceList({
    String? search,
    int? level,
    String? operationTypeId,
    String? room,
    String overallStatus = 'ALL',
    bool? dietaryNotViewed,
    bool? healthEducationNotViewed,
    bool? missedMorning,
    bool? missedAfternoon,
    bool? missedBoth,
    int page = 1,
    int limit = 20,
  });
}
