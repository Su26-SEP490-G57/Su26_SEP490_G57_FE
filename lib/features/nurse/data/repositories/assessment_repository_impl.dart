import 'package:poms/features/nurse/domain/models/assessment_summary.dart';
import 'package:poms/features/nurse/domain/repositories/assessment_repository.dart';
import 'package:poms/features/nurse/data/datasources/assessment_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/assessment_detail.dart';

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

  @override
  Future<List<AssessmentDetail>> getAssessmentHistory(
    String caseId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dataSource.getAssessmentHistory(
      caseId,
      page: page,
      limit: limit,
    );

    return response.data.map((e) => e.toDomain()).toList();
  }
}
