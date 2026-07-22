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
    this.errorMessage,
  });

  final AssessmentStatusState status;
  final AssessmentSummary? assessment;
  final AssessmentDetail? detail;
  final String? errorMessage;

  bool get isLoading => status == AssessmentStatusState.loading;

  AssessmentState copyWith({
    AssessmentStatusState? status,
    AssessmentSummary? assessment,
    AssessmentDetail? detail,
    String? errorMessage,
  }) {
    return AssessmentState(
      status: status ?? this.status,
      assessment: assessment ?? this.assessment,
      detail: detail ?? this.detail,
      errorMessage: errorMessage,
    );
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  AssessmentNotifier(this._repository) : super(const AssessmentState());

  final AssessmentRepository _repository;

  Future<void> loadLatestAssessment(String caseId) async {
    state = state.copyWith(status: AssessmentStatusState.loading);

    try {
      final assessment = await _repository.getLatestAssessment(caseId);

      final detail = await _repository.getAssessmentDetail(
        assessment.assessmentId,
      );

      state = AssessmentState(
        status: AssessmentStatusState.loaded,
        assessment: assessment,
        detail: detail,
      );
    } on DioException catch (e) {
      String message;

      switch (e.response?.statusCode) {
        case 404:
          message = 'Chưa có dữ liệu đánh giá của bệnh nhân.';
          break;

        default:
          message = 'Không thể kết nối tới máy chủ. Vui lòng thử lại.';
      }

      state = AssessmentState(
        status: AssessmentStatusState.error,
        errorMessage: message,
      );
    } catch (_) {
      state = const AssessmentState(
        status: AssessmentStatusState.error,
        errorMessage: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }
}

final assessmentNotifierProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
      return AssessmentNotifier(ref.watch(assessmentRepositoryProvider));
    });
