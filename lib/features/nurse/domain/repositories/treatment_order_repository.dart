import 'dart:typed_data';

import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet_prefill.dart';

abstract interface class TreatmentOrderRepository {
  Future<List<TreatmentOrder>> getHistory(String caseId);

  Future<List<TreatmentSheet>> getSheets(String caseId);

  Future<TreatmentSheetPrefill> getSheetPrefill(String caseId);

  Future<TreatmentOrder> createOrder({
    required String caseId,
    required CareLevel careLevel,
    required String instructions,
    required TreatmentSheetInput sheet,
  });

  Future<Uint8List> getTreatmentSheetPdf(String caseId, int sheetId);
}
