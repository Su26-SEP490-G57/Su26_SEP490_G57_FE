import 'package:poms/features/nurse/data/datasources/care_observation_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
import 'package:poms/features/nurse/domain/repositories/care_observation_repository.dart';

class CareObservationRepositoryImpl implements CareObservationRepository {
  CareObservationRepositoryImpl(this._dataSource);

  final CareObservationRemoteDataSource _dataSource;

  @override
  Future<List<CareObservationTask>> getMyTasks() => _dataSource.getMyTasks();

  @override
  Future<CareObservationTask?> getTaskForPatient(String caseId) =>
      _dataSource.getTaskForPatient(caseId);

  @override
  Future<CareObservationTask> getTaskDetail(int taskId) =>
      _dataSource.getTaskDetail(taskId);

  @override
  Future<CareObservationEntry> submitEntry({
    required int taskId,
    required Map<String, String> findings,
    String? note,
  }) {
    return _dataSource.submitEntry(
      taskId: taskId,
      findings: findings,
      note: note,
    );
  }
}
