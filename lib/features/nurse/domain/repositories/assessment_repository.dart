import 'package:poms/features/nurse/domain/models/assessment_detail.dart';
import 'package:poms/features/nurse/domain/models/assessment_summary.dart';

abstract interface class AssessmentRepository {
  Future<AssessmentSummary> getLatestAssessment(String caseId);

  Future<AssessmentDetail> getAssessmentDetail(int assessmentId);

  Future<List<AssessmentDetail>> getAssessmentHistory(
    String caseId, {
    int page = 1,
    int limit = 10,
  });
}
