import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/vital_signs_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/vital_signs_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/vital_signs_record.dart';
import 'package:poms/features/nurse/domain/repositories/vital_signs_repository.dart';

final vitalSignsRemoteDatasourceProvider = Provider<VitalSignsRemoteDataSource>(
  (ref) {
    return VitalSignsRemoteDataSource(ref.watch(appDioProvider));
  },
);

final vitalSignsRepositoryProvider = Provider<VitalSignsRepository>((ref) {
  return VitalSignsRepositoryImpl(
    ref.watch(vitalSignsRemoteDatasourceProvider),
  );
});

enum VitalSignsStatusState { initial, loading, loaded, error }

class VitalSignsState {
  const VitalSignsState({
    this.status = VitalSignsStatusState.initial,
    this.history = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  final VitalSignsStatusState status;
  final List<VitalSignsRecord> history;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isLoading => status == VitalSignsStatusState.loading;

  VitalSignsState copyWith({
    VitalSignsStatusState? status,
    List<VitalSignsRecord>? history,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return VitalSignsState(
      status: status ?? this.status,
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class VitalSignsNotifier extends StateNotifier<VitalSignsState> {
  VitalSignsNotifier(this._repository, this._caseId)
    : super(const VitalSignsState()) {
    unawaited(loadHistory());
  }

  final VitalSignsRepository _repository;
  final String _caseId;

  Future<void> loadHistory() async {
    if (!mounted) return;

    state = state.copyWith(status: VitalSignsStatusState.loading);

    try {
      final history = await _repository.getHistory(_caseId);

      if (!mounted) return;

      state = state.copyWith(
        status: VitalSignsStatusState.loaded,
        history: history,
      );
    } on DioException catch (e) {
      developer.log(
        'VitalSignsNotifier DioException: status=${e.response?.statusCode} body=${e.response?.data}',
        name: 'VitalSignsNotifier',
        error: e,
      );

      if (!mounted) return;

      final String message;
      switch (e.response?.statusCode) {
        case 404:
          message = 'Chưa có dữ liệu chỉ số sinh tồn của người bệnh.';
        default:
          message = 'Không thể tải lịch sử chỉ số sinh tồn.';
      }

      state = state.copyWith(
        status: VitalSignsStatusState.error,
        errorMessage: message,
      );
    } catch (e, st) {
      developer.log(
        'VitalSignsNotifier unexpected error: $e',
        name: 'VitalSignsNotifier',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;

      state = state.copyWith(
        status: VitalSignsStatusState.error,
        errorMessage: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  /// Trả về bản ghi máy chủ vừa tạo (đã kèm người ghi nhận + thời điểm do máy
  /// chủ gán), hoặc null nếu thất bại.
  Future<VitalSignsRecord?> submit({
    required int pulseBpm,
    required int bloodPressureSystolic,
    required int bloodPressureDiastolic,
    required double temperatureCelsius,
    required int respiratoryRate,
    required int spo2Percent,
    String? note,
  }) async {
    if (!mounted) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      final record = await _repository.createVitalSigns(
        caseId: _caseId,
        pulseBpm: pulseBpm,
        bloodPressureSystolic: bloodPressureSystolic,
        bloodPressureDiastolic: bloodPressureDiastolic,
        temperatureCelsius: temperatureCelsius,
        respiratoryRate: respiratoryRate,
        spo2Percent: spo2Percent,
        note: note,
      );

      if (!mounted) return record;

      // Prepend bản ghi máy chủ trả về — không tự dựng dữ liệu ở client.
      state = state.copyWith(
        status: VitalSignsStatusState.loaded,
        history: [record, ...state.history],
        isSubmitting: false,
      );

      return record;
    } catch (e, st) {
      developer.log(
        'VitalSignsNotifier submit error: $e',
        name: 'VitalSignsNotifier',
        error: e,
        stackTrace: st,
      );

      if (mounted) state = state.copyWith(isSubmitting: false);

      return null;
    }
  }
}

final vitalSignsNotifierProvider =
    StateNotifierProvider.family<VitalSignsNotifier, VitalSignsState, String>((
      ref,
      caseId,
    ) {
      return VitalSignsNotifier(
        ref.watch(vitalSignsRepositoryProvider),
        caseId,
      );
    });
