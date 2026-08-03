import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/data/datasources/survey_remote_datasource.dart';
import 'package:poms/features/patient/data/repositories/survey_repository_impl.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/domain/repositories/survey_repository.dart';

// ── DI ────────────────────────────────────────────────────────────────────────

final surveyRemoteDataSourceProvider = Provider<SurveyRemoteDataSource>((ref) {
  final dio = ref.watch(appDioProvider);
  return SurveyRemoteDataSource(dio);
});

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  final dataSource = ref.watch(surveyRemoteDataSourceProvider);
  return SurveyRepositoryImpl(dataSource);
});

// ── GET /symptom-surveys/questions ───────────────────────────────────────────

final surveyQuestionsProvider = FutureProvider<List<SurveyQuestion>>((ref) {
  return ref.watch(surveyRepositoryProvider).getQuestions();
});

// ── Assessment submit notifier ────────────────────────────────────────────────

enum AssessmentStatus { idle, loading, success, error }

class AssessmentState {
  const AssessmentState({
    this.status = AssessmentStatus.idle,
    this.result,
    this.errorMessage,
  });

  final AssessmentStatus status;
  final SurveySubmitResult? result;
  final String? errorMessage;

  bool get isLoading => status == AssessmentStatus.loading;

  AssessmentState copyWith({
    AssessmentStatus? status,
    SurveySubmitResult? result,
    String? errorMessage,
  }) {
    return AssessmentState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  AssessmentNotifier(this._repository) : super(const AssessmentState());

  final SurveyRepository _repository;

  Future<void> submit({
    required String caseId,
    required List<SurveyAnswer> answers,
    int? podContext,
    String? shiftPeriod,
  }) async {
    state = state.copyWith(status: AssessmentStatus.loading);
    try {
      final result = await _repository.submitSurvey(
        SurveySubmitRequest(
          caseId: caseId,
          answers: answers,
          podContext: podContext,
          shiftPeriod: shiftPeriod,
        ),
      );
      state = AssessmentState(status: AssessmentStatus.success, result: result);
    } catch (e) {
      state = AssessmentState(
        status: AssessmentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const AssessmentState();
}

final assessmentNotifierProvider =
    StateNotifierProvider.autoDispose<AssessmentNotifier, AssessmentState>(
      (ref) => AssessmentNotifier(ref.watch(surveyRepositoryProvider)),
    );
