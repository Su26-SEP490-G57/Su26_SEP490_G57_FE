import '../../domain/models/assessment_summary.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/assessment_remote_datasource.dart';
import '../../domain/models/assessment_detail.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  AssessmentRepositoryImpl(this._dataSource);

  final AssessmentRemoteDataSource _dataSource;

  @override
  Future<AssessmentSummary> getLatestAssessment(String caseId) async {
    final response = await _dataSource.getLatestAssessment(caseId);

    return response.toDomain();
  }

  @override
  Future<AssessmentDetail> getAssessmentDetail(int assessmentId) async {
    final response = await _dataSource.getAssessmentDetail(assessmentId);

    return response.toDomain();
  }
}
