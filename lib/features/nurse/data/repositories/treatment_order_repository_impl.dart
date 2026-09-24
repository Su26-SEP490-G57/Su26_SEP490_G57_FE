import 'dart:typed_data';

import 'package:poms/features/nurse/data/datasources/treatment_order_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet_prefill.dart';
import 'package:poms/features/nurse/domain/repositories/treatment_order_repository.dart';

class TreatmentOrderRepositoryImpl implements TreatmentOrderRepository {
  TreatmentOrderRepositoryImpl(this._dataSource);

  final TreatmentOrderRemoteDataSource _dataSource;

  @override
  Future<List<TreatmentOrder>> getHistory(String caseId) {
    return _dataSource.getHistory(caseId);
  }

  @override
  Future<List<TreatmentSheet>> getSheets(String caseId) {
    return _dataSource.getSheets(caseId);
  }

  @override
  Future<TreatmentSheetPrefill> getSheetPrefill(String caseId) {
    return _dataSource.getSheetPrefill(caseId);
  }

  @override
  Future<TreatmentOrder> createOrder({
    required String caseId,
    required CareLevel careLevel,
    required String instructions,
    required TreatmentSheetInput sheet,
  }) {
    return _dataSource.createOrder(
      caseId: caseId,
      careLevel: careLevel,
      instructions: instructions,
      sheet: sheet,
    );
  }

  @override
  Future<Uint8List> getTreatmentSheetPdf(String caseId, int sheetId) =>
      _dataSource.getTreatmentSheetPdf(caseId, sheetId);
}
