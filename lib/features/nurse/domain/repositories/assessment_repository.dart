import '../models/assessment_detail.dart';
import '../models/assessment_summary.dart';

abstract interface class AssessmentRepository {
  Future<AssessmentSummary> getLatestAssessment(
    String caseId,
  );

  Future<AssessmentDetail> getAssessmentDetail(int assessmentId);
}