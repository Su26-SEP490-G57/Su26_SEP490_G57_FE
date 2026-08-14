import 'package:poms/core/utils/exception_handler.dart';
import 'package:poms/features/patient/data/datasources/engagement_remote_datasource.dart';
import 'package:poms/features/patient/domain/repositories/engagement_repository.dart';

class EngagementRepositoryImpl implements EngagementRepository {
  EngagementRepositoryImpl(this._dataSource);

  final EngagementRemoteDataSource _dataSource;

  @override
  Future<void> logEngagement({
    required String caseId,
    bool? viewedGuidance,
    bool? viewedEducation,
  }) async {
    try {
      await _dataSource.logEngagement(
        caseId,
        viewedGuidance: viewedGuidance,
        viewedEducation: viewedEducation,
      );
    } catch (e) {
      throw mapException(e);
    }
  }
}
