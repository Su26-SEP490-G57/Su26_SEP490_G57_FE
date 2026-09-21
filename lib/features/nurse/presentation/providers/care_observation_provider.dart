import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/care_observation_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/care_observation_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
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
// Phiếu theo dõi của MỘT người bệnh (màn hình điền phiếu)
// ─────────────────────────────────────────────────────────────────────────────

class CareObservationState {
  const CareObservationState({
    this.status = CareObservationStatusState.initial,
    this.task,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final CareObservationStatusState status;
  final CareObservationTask? task;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isLoading => status == CareObservationStatusState.loading;

  CareObservationState copyWith({
    CareObservationStatusState? status,
    CareObservationTask? task,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CareObservationState(
      status: status ?? this.status,
      task: task ?? this.task,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class CareObservationNotifier extends StateNotifier<CareObservationState> {
  CareObservationNotifier(this._repository, this._caseId)
    : super(const CareObservationState()) {
    unawaited(load());
  }

  final CareObservationRepository _repository;
  final String _caseId;

  Future<void> load() async {
    if (!mounted) return;

    state = state.copyWith(status: CareObservationStatusState.loading);

    try {
      final task = await _repository.getTaskForPatient(_caseId);

      if (!mounted) return;

      state = CareObservationState(
        status: CareObservationStatusState.loaded,
        task: task,
        errorMessage: task == null
            ? 'Người bệnh chưa được chỉ định mức chăm sóc nên chưa có phiếu theo dõi.'
            : null,
      );
    } catch (e, st) {
      developer.log(
        'CareObservationNotifier load error: $e',
        name: 'CareObservationNotifier',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;

      state = state.copyWith(
        status: CareObservationStatusState.error,
        errorMessage: 'Không thể tải phiếu theo dõi chăm sóc.',
      );
    }
  }

  Future<CareObservationEntry?> submitEntry({
    required Map<String, String> findings,
    String? note,
  }) async {
    final task = state.task;
    if (task == null || !mounted) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      final entry = await _repository.submitEntry(
        taskId: task.taskId,
        findings: findings,
        note: note,
      );

      if (!mounted) return entry;

      state = state.copyWith(isSubmitting: false);
      // Tải lại để lấy danh sách lượt ghi nhận mới nhất từ máy chủ.
      unawaited(load());

      return entry;
    } catch (e, st) {
      developer.log(
        'CareObservationNotifier submitEntry error: $e',
        name: 'CareObservationNotifier',
        error: e,
        stackTrace: st,
      );

      if (mounted) state = state.copyWith(isSubmitting: false);

      return null;
    }
  }
}

final careObservationNotifierProvider =
    StateNotifierProvider.family<
      CareObservationNotifier,
      CareObservationState,
      String
    >((ref, caseId) {
      return CareObservationNotifier(
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
