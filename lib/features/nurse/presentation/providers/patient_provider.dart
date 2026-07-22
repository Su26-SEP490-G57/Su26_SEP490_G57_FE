import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/domain/repositories/patient_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/patient_remote_datasource.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../domain/models/patient_summary.dart';

final patientRemoteDatasourceProvider = Provider<PatientRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(appDioProvider);

  return PatientRemoteDataSource(dio);
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl(ref.watch(patientRemoteDatasourceProvider));
});

enum PatientStatusState { initial, loading, loaded, error }

class PatientState {
  final int currentPage;
  final int total;
  final int limit;
  int get totalPages => limit == 0 ? 1 : (total / limit).ceil();
  int get startIndex {
    if (total == 0) return 0;
    return (currentPage - 1) * limit + 1;
  }

  int get endIndex {
    if (total == 0) return 0;

    final end = currentPage * limit;
    return end > total ? total : end;
  }

  const PatientState({
    this.status = PatientStatusState.initial,
    this.patients = const [],
    this.currentPage = 1,
    this.total = 0,
    this.limit = 10,
    this.errorMessage,
  });

  final PatientStatusState status;

  final List<PatientSummary> patients;

  final String? errorMessage;

  bool get isLoading => status == PatientStatusState.loading;

  PatientState copyWith({
    PatientStatusState? status,
    List<PatientSummary>? patients,
    int? currentPage,
    int? total,
    int? limit,
    String? errorMessage,
  }) {
    return PatientState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier(this._repository) : super(const PatientState()) {
    loadPatients();
  }

  final PatientRepository _repository;

  Future<void> loadPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 1000,
  }) async {
    state = state.copyWith(status: PatientStatusState.loading);

    try {
      final patientPage = await _repository.getPatients(
        search: search,
        level: level,
        operationTypeId: operationTypeId,
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
        limit: limit,
      );

      state = state.copyWith(
        status: PatientStatusState.loaded,
        patients: patientPage.patients,
        currentPage: patientPage.page,
        total: patientPage.total,
        limit: patientPage.limit,
      );
    } catch (e) {

      state = state.copyWith(
        status: PatientStatusState.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final patientNotifierProvider =
    StateNotifierProvider<PatientNotifier, PatientState>((ref) {
      return PatientNotifier(ref.watch(patientRepositoryProvider));
    });
