import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/treatment_order_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/treatment_order_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_order.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet_prefill.dart';
import 'package:poms/features/nurse/domain/repositories/treatment_order_repository.dart';

final treatmentOrderRemoteDatasourceProvider =
    Provider<TreatmentOrderRemoteDataSource>((ref) {
      return TreatmentOrderRemoteDataSource(ref.watch(appDioProvider));
    });

final treatmentOrderRepositoryProvider = Provider<TreatmentOrderRepository>((
  ref,
) {
  return TreatmentOrderRepositoryImpl(
    ref.watch(treatmentOrderRemoteDatasourceProvider),
  );
});

enum TreatmentOrderStatusState { initial, loading, loaded, error }

class TreatmentOrderState {
  const TreatmentOrderState({
    this.status = TreatmentOrderStatusState.initial,
    this.history = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  final TreatmentOrderStatusState status;
  final List<TreatmentOrder> history;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isLoading => status == TreatmentOrderStatusState.loading;

  TreatmentOrder? get activeOrder => history.isEmpty ? null : history.first;

  TreatmentOrderState copyWith({
    TreatmentOrderStatusState? status,
    List<TreatmentOrder>? history,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return TreatmentOrderState(
      status: status ?? this.status,
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class TreatmentOrderNotifier extends StateNotifier<TreatmentOrderState> {
  TreatmentOrderNotifier(this._repository, this._caseId)
    : super(const TreatmentOrderState()) {
    unawaited(loadHistory());
  }

  final TreatmentOrderRepository _repository;
  final String _caseId;

  Future<void> loadHistory() async {
    if (!mounted) return;

    state = state.copyWith(status: TreatmentOrderStatusState.loading);

    try {
      final history = await _repository.getHistory(_caseId);

      if (!mounted) return;

      state = state.copyWith(
        status: TreatmentOrderStatusState.loaded,
        history: history,
      );
    } catch (e, st) {
      developer.log(
        'TreatmentOrderNotifier loadHistory error: $e',
        name: 'TreatmentOrderNotifier',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;

      state = state.copyWith(
        status: TreatmentOrderStatusState.error,
        errorMessage: 'Không thể tải lịch sử chỉ định điều trị.',
      );
    }
  }

  /// Lưu "Phiếu theo dõi điều trị" (kèm mức chăm sóc). Lỗi được ghi vào
  /// `errorMessage` để form hiển thị.
  Future<TreatmentOrder?> submit({
    required CareLevel careLevel,
    required String instructions,
    required TreatmentSheetInput sheet,
  }) async {
    if (!mounted) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      final order = await _repository.createOrder(
        caseId: _caseId,
        careLevel: careLevel,
        instructions: instructions,
        sheet: sheet,
      );

      if (!mounted) return order;

      state = state.copyWith(
        status: TreatmentOrderStatusState.loaded,
        history: [order, ...state.history],
        isSubmitting: false,
      );

      return order;
    } catch (e, st) {
      developer.log(
        'TreatmentOrderNotifier submit error: $e',
        name: 'TreatmentOrderNotifier',
        error: e,
        stackTrace: st,
      );

      if (mounted) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _submitErrorMessage(e),
        );
      }

      return null;
    }
  }
}

String _submitErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 502) {
      return 'Không kết nối được HIS — phiếu chưa được lưu.';
    }
    if (status == 400) {
      return 'Thông tin phiếu không hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (status == 403) return 'Chỉ bác sĩ mới được lập phiếu điều trị.';
  }
  return 'Không thể lưu phiếu theo dõi điều trị. Vui lòng thử lại.';
}

/// Danh sách "Phiếu theo dõi điều trị" (lưu ở HIS), mới nhất trước. Được
/// invalidate sau khi bác sĩ lưu phiếu mới.
final treatmentSheetsProvider = FutureProvider.autoDispose
    .family<List<TreatmentSheet>, String>((ref, caseId) {
      return ref.watch(treatmentOrderRepositoryProvider).getSheets(caseId);
    });

/// Dữ liệu tự điền cho phiếu mới — autoDispose để mỗi lần mở form đều lấy
/// chỉ số sinh tồn / tờ số mới nhất.
final treatmentSheetPrefillProvider = FutureProvider.autoDispose
    .family<TreatmentSheetPrefill, String>((ref, caseId) {
      return ref
          .watch(treatmentOrderRepositoryProvider)
          .getSheetPrefill(caseId);
    });

final treatmentOrderNotifierProvider =
    StateNotifierProvider.family<
      TreatmentOrderNotifier,
      TreatmentOrderState,
      String
    >((ref, caseId) {
      return TreatmentOrderNotifier(
        ref.watch(treatmentOrderRepositoryProvider),
        caseId,
      );
    });
