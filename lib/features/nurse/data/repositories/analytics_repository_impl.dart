import 'package:poms/core/utils/exception_handler.dart';
import 'package:poms/features/nurse/data/datasources/analytics_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';
import 'package:poms/features/nurse/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._dataSource);

  final AnalyticsRemoteDataSource _dataSource;

  @override
  Future<ComplianceOverview> getComplianceOverview() async {
    try {
      final response = await _dataSource.getOverview();
      final compliance = response.compliance;
      return ComplianceOverview(
        compliant: compliance.compliant,
        nonCompliant: compliance.nonCompliant,
        complianceRate: compliance.complianceRate,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<PatientCompliance> getPatientCompliance(String caseId) async {
    try {
      final response = await _dataSource.getPatientCompliance(caseId);
      return PatientCompliance(
        caseId: response.caseId,
        viewedGuidance: response.viewedGuidance,
        viewedEducation: response.viewedEducation,
        reminderCount: response.reminderCount,
        appAccessCount: response.appAccessCount,
        assessmentCompletedCount: response.assessmentCompletedCount,
        isCompliant: response.isCompliant,
        morningAssessmentStatus: ScheduledAssessmentStatus.fromApi(
          response.morningAssessmentStatus,
        ),
        afternoonAssessmentStatus: ScheduledAssessmentStatus.fromApi(
          response.afternoonAssessmentStatus,
        ),
        isDailyCompliant: response.isDailyCompliant,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AssessmentMatrix> getAssessmentMatrix(String caseId) async {
    try {
      final response = await _dataSource.getAssessmentMatrix(caseId);
      return AssessmentMatrix(
        caseId: response.caseId,
        pods: response.pods,
        questions: response.questions
            .map(
              (q) => AssessmentMatrixQuestion(
                questionId: q.questionId,
                questionText: q.questionText,
                cells: q.cells
                    .map(
                      (c) => AssessmentMatrixCell(pod: c.pod, score: c.score),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    } catch (e) {
      throw mapException(e);
    }
  }
}
