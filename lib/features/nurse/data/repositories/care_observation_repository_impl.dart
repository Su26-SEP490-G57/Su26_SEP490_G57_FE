import 'dart:typed_data';

import 'package:poms/features/nurse/data/datasources/care_observation_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
import 'package:poms/features/nurse/domain/models/care_sheet.dart';
import 'package:poms/features/nurse/domain/repositories/care_observation_repository.dart';

class CareObservationRepositoryImpl implements CareObservationRepository {
  CareObservationRepositoryImpl(this._dataSource);

  final CareObservationRemoteDataSource _dataSource;

  @override
  Future<List<CareObservationTask>> getMyTasks() => _dataSource.getMyTasks();

  @override
  Future<CareSheetList> getCareSheets(String caseId) =>
      _dataSource.getCareSheets(caseId);

  @override
  Future<CareSheetPrefill> getCareSheetPrefill(String caseId) =>
      _dataSource.getCareSheetPrefill(caseId);

  @override
  Future<CareSheet> createCareSheet({
    required String caseId,
    required CareSheetInput sheet,
  }) {
    return _dataSource.createCareSheet(caseId: caseId, sheet: sheet);
  }

  @override
  Future<Uint8List> getCareSheetPdf(String caseId, int sheetId) =>
      _dataSource.getCareSheetPdf(caseId, sheetId);
}
