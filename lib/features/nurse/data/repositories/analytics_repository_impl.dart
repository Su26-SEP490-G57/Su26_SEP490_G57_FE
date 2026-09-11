import 'package:poms/core/utils/exception_handler.dart';
import 'package:poms/features/nurse/data/datasources/analytics_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance_list_page.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance_summary.dart';
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

  @override
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
  }) async {
    try {
      final response = await _dataSource.getComplianceList(
        search: search,
        level: level,
        operationTypeId: operationTypeId,
        room: room,
        overallStatus: overallStatus,
        dietaryNotViewed: dietaryNotViewed,
        healthEducationNotViewed: healthEducationNotViewed,
        missedMorning: missedMorning,
        missedAfternoon: missedAfternoon,
        missedBoth: missedBoth,
        page: page,
        limit: limit,
      );
      return PatientComplianceListPage(
        items: response.data
            .map(
              (item) => PatientComplianceSummary(
                caseId: item.caseId,
                fullName: item.fullName,
                roomBed: item.roomBed,
                currentPod: item.currentPod,
                level: item.level,
                levelName: item.levelName,
                viewedGuidance: item.viewedGuidance,
                viewedEducation: item.viewedEducation,
                morningAssessmentStatus: ScheduledAssessmentStatus.fromApi(
                  item.morningAssessmentStatus,
                ),
                afternoonAssessmentStatus: ScheduledAssessmentStatus.fromApi(
                  item.afternoonAssessmentStatus,
                ),
                complianceRate: item.complianceRate,
                isCompliant: item.isCompliant,
                isDailyCompliant: item.isDailyCompliant,
              ),
            )
            .toList(),
        total: response.total,
        page: response.page,
        limit: response.limit,
      );
    } catch (e) {
      throw mapException(e);
    }
  }
}
