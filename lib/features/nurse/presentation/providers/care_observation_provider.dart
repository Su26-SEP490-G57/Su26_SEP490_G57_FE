import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/care_observation_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/care_observation_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
import 'package:poms/features/nurse/domain/models/care_sheet.dart';
import 'package:poms/features/nurse/domain/repositories/care_observation_repository.dart';

final careObservationRemoteDatasourceProvider =
    Provider<CareObservationRemoteDataSource>((ref) {
      return CareObservationRemoteDataSource(ref.watch(appDioProvider));
    });

final careObservationRepositoryProvider = Provider<CareObservationRepository>((
  ref,
) {
  return CareObservationRepositoryImpl(
    ref.watch(careObservationRemoteDatasourceProvider),
  );
});

enum CareObservationStatusState { initial, loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Phiếu theo dõi và chăm sóc (Cấp 1 / Cấp 2-3) — lưu ở HIS
// ─────────────────────────────────────────────────────────────────────────────

/// Danh sách phiếu chăm sóc của một người bệnh, mới nhất trước. Được
/// invalidate sau khi điều dưỡng lưu phiếu mới.
final careSheetsProvider = FutureProvider.autoDispose
    .family<CareSheetList, String>((ref, caseId) {
      return ref.watch(careObservationRepositoryProvider).getCareSheets(caseId);
    });

/// Dữ liệu tự điền cho phiếu mới — autoDispose để mỗi lần mở form đều lấy
/// chỉ số sinh tồn / tờ số mới nhất.
final careSheetPrefillProvider = FutureProvider.autoDispose
    .family<CareSheetPrefill, String>((ref, caseId) {
      return ref
          .watch(careObservationRepositoryProvider)
          .getCareSheetPrefill(caseId);
    });

class CareSheetSubmitState {
  const CareSheetSubmitState({this.isSubmitting = false, this.errorMessage});

  final bool isSubmitting;
  final String? errorMessage;
}

/// Lưu phiếu chăm sóc; lỗi được ghi vào `errorMessage` để form hiển thị.
class CareSheetSubmitNotifier extends StateNotifier<CareSheetSubmitState> {
  CareSheetSubmitNotifier(this._repository, this._caseId)
    : super(const CareSheetSubmitState());

  final CareObservationRepository _repository;
  final String _caseId;

  Future<CareSheet?> submit(CareSheetInput sheet) async {
    if (!mounted) return null;

    state = const CareSheetSubmitState(isSubmitting: true);

    try {
      final saved = await _repository.createCareSheet(
        caseId: _caseId,
        sheet: sheet,
      );
      if (mounted) state = const CareSheetSubmitState();
      return saved;
    } catch (e, st) {
      developer.log(
        'CareSheetSubmitNotifier submit error: $e',
        name: 'CareSheetSubmitNotifier',
        error: e,
        stackTrace: st,
      );

      if (mounted) {
        state = CareSheetSubmitState(errorMessage: _submitErrorMessage(e));
      }
      return null;
    }
  }
}

String _submitErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 502:
        return 'Không kết nối được HIS — phiếu chưa được lưu.';
      case 409:
        return 'Người bệnh chưa được bác sĩ chỉ định mức chăm sóc.';
      case 400:
        return 'Thông tin phiếu không hợp lệ. Vui lòng kiểm tra lại.';
      case 403:
        return 'Bạn không có quyền lập phiếu chăm sóc.';
    }
  }
  return 'Không thể lưu phiếu chăm sóc. Vui lòng thử lại.';
}

final careSheetSubmitProvider = StateNotifierProvider.autoDispose
    .family<CareSheetSubmitNotifier, CareSheetSubmitState, String>((
      ref,
      caseId,
    ) {
      return CareSheetSubmitNotifier(
        ref.watch(careObservationRepositoryProvider),
        caseId,
      );
    });

// ─────────────────────────────────────────────────────────────────────────────
// Danh sách nhiệm vụ của điều dưỡng đang đăng nhập (xuyên suốt nhiều người bệnh)
// ─────────────────────────────────────────────────────────────────────────────

class CareObservationTasksState {
  const CareObservationTasksState({
    this.status = CareObservationStatusState.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  final CareObservationStatusState status;
  final List<CareObservationTask> tasks;
  final String? errorMessage;

  bool get isLoading => status == CareObservationStatusState.loading;

  CareObservationTasksState copyWith({
    CareObservationStatusState? status,
    List<CareObservationTask>? tasks,
    String? errorMessage,
  }) {
    return CareObservationTasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }
}

class CareObservationTasksNotifier
    extends StateNotifier<CareObservationTasksState> {
  CareObservationTasksNotifier(this._repository)
    : super(const CareObservationTasksState()) {
    unawaited(load());
  }

  final CareObservationRepository _repository;

  Future<void> load() async {
    if (!mounted) return;

    state = state.copyWith(status: CareObservationStatusState.loading);

    try {
      final tasks = await _repository.getMyTasks();

      if (!mounted) return;

      state = state.copyWith(
        status: CareObservationStatusState.loaded,
        tasks: tasks,
      );
    } catch (e, st) {
      developer.log(
        'CareObservationTasksNotifier load error: $e',
        name: 'CareObservationTasksNotifier',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;

      state = state.copyWith(
        status: CareObservationStatusState.error,
        errorMessage: 'Không thể tải danh sách nhiệm vụ theo dõi chăm sóc.',
      );
    }
  }
}

final careObservationTasksNotifierProvider =
    StateNotifierProvider<
      CareObservationTasksNotifier,
      CareObservationTasksState
    >((ref) {
      return CareObservationTasksNotifier(
        ref.watch(careObservationRepositoryProvider),
      );
    });
