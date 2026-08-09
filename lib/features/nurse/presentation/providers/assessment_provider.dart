import 'dart:async';

//import 'package:flutter/material.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import 'package:poms/features/nurse/data/datasources/assessment_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/assessment_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/assessment_summary.dart';
import 'package:poms/features/nurse/domain/repositories/assessment_repository.dart';
import 'package:poms/features/nurse/domain/models/assessment_detail.dart';

final assessmentRemoteDatasourceProvider = Provider<AssessmentRemoteDataSource>(
  (ref) {
    final dio = ref.watch(appDioProvider);

    return AssessmentRemoteDataSource(dio);
  },
);

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepositoryImpl(
    ref.watch(assessmentRemoteDatasourceProvider),
  );
});

enum AssessmentStatusState { initial, loading, loaded, error }

class AssessmentState {
  const AssessmentState({
    this.status = AssessmentStatusState.initial,
    this.assessment,
    this.detail,
    this.history = const [],
    this.selectedAssessmentId,
    this.errorMessage,
  });

  final AssessmentStatusState status;
  final AssessmentSummary? assessment;
  final AssessmentDetail? detail;
  final List<AssessmentDetail> history;
  final int? selectedAssessmentId;
  final String? errorMessage;

  bool get isLoading => status == AssessmentStatusState.loading;

  AssessmentDetail? get selectedAssessment {
    if (selectedAssessmentId == null) {
      return detail;
    }

    for (final item in history) {
      if (item.assessmentId == selectedAssessmentId) {
        return item;
      }
    }

    return detail;
  }

  AssessmentState copyWith({
    AssessmentStatusState? status,
    AssessmentSummary? assessment,
    AssessmentDetail? detail,
    List<AssessmentDetail>? history,
    int? selectedAssessmentId,
    String? errorMessage,
  }) {
    return AssessmentState(
      status: status ?? this.status,
      assessment: assessment ?? this.assessment,
      detail: detail ?? this.detail,
      history: history ?? this.history,
      selectedAssessmentId: selectedAssessmentId ?? this.selectedAssessmentId,
      errorMessage: errorMessage,
    );
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  AssessmentNotifier(this._repository, this._caseId)
    : super(const AssessmentState()) {
    unawaited(loadAssessmentHistory());
  }

  final AssessmentRepository _repository;
  final String _caseId;

  Future<void> loadAssessmentHistory() async {
    if (!mounted) return;

    state = state.copyWith(status: AssessmentStatusState.loading);

    try {
      final history = await _repository.getAssessmentHistory(_caseId);

      if (!mounted) return;

      state = state.copyWith(
        status: AssessmentStatusState.loaded,
        history: history,
        detail: history.isEmpty ? null : history.first,
        selectedAssessmentId: history.isEmpty
            ? null
            : history.first.assessmentId,
      );
    } on DioException catch (e) {
      String message;

      switch (e.response?.statusCode) {
        case 404:
          message = 'Chưa có dữ liệu đánh giá của bệnh nhân.';
          break;
        default:
          message =
              'Không có dữ liệu đánh giá hoặc không thể kết nối tới máy chủ.';
      }

      if (!mounted) return;

      state = state.copyWith(
        status: AssessmentStatusState.error,
        errorMessage: message,
      );
    } catch (_) {
      if (!mounted) return;

      state = state.copyWith(
        status: AssessmentStatusState.error,
        errorMessage: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  void selectAssessment(int assessmentId) {
    if (!mounted) return;

    state = state.copyWith(selectedAssessmentId: assessmentId);
  }

  void appendAssessment(AssessmentDetail assessment) {
    if (!mounted) return;

    state = state.copyWith(
      history: [assessment, ...state.history],
      selectedAssessmentId: assessment.assessmentId,
    );
  }
}

final assessmentNotifierProvider =
    StateNotifierProvider.family<AssessmentNotifier, AssessmentState, String>((
      ref,
      caseId,
    ) {
      return AssessmentNotifier(
        ref.watch(assessmentRepositoryProvider),
        caseId,
      );
    });
