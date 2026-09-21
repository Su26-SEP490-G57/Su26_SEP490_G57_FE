import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';

abstract interface class CareObservationRepository {
  Future<List<CareObservationTask>> getMyTasks();

  Future<CareObservationTask?> getTaskForPatient(String caseId);

  Future<CareObservationTask> getTaskDetail(int taskId);

  Future<CareObservationEntry> submitEntry({
    required int taskId,
    required Map<String, String> findings,
    String? note,
  });
}
