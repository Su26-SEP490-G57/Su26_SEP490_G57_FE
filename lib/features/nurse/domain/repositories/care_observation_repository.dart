import 'dart:typed_data';

import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
import 'package:poms/features/nurse/domain/models/care_sheet.dart';

abstract interface class CareObservationRepository {
  Future<List<CareObservationTask>> getMyTasks();

  Future<CareSheetList> getCareSheets(String caseId);

  Future<CareSheetPrefill> getCareSheetPrefill(String caseId);

  Future<CareSheet> createCareSheet({
    required String caseId,
    required CareSheetInput sheet,
  });

  Future<Uint8List> getCareSheetPdf(String caseId, int sheetId);
}
