import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/doctor/data/datasources/doctor_patient_remote_datasource.dart';
import 'package:poms/features/doctor/data/repositories/doctor_patient_repository_impl.dart';
import 'package:poms/features/doctor/domain/repositories/doctor_patient_repository.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

final doctorPatientRemoteDatasourceProvider =
    Provider<DoctorPatientRemoteDataSource>((ref) {
      return DoctorPatientRemoteDataSource(ref.watch(appDioProvider));
    });

final doctorPatientRepositoryProvider = Provider<DoctorPatientRepository>((ref) {
  return DoctorPatientRepositoryImpl(
    ref.watch(doctorPatientRemoteDatasourceProvider),
  );
});

// ── State ──────────────────────────────────────────────────────────────────

class DoctorPatientsState {
  const DoctorPatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  final List<PatientSummary> patients;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  DoctorPatientsState copyWith({
    List<PatientSummary>? patients,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return DoctorPatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────

class DoctorPatientsNotifier extends StateNotifier<DoctorPatientsState> {
  DoctorPatientsNotifier(this._repository) : super(const DoctorPatientsState()) {
    loadPatients();
  }

  final DoctorPatientRepository _repository;

  Future<void> loadPatients({String? search}) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final patients = await _repository.getAllPatients(
        search: search,
        limit: 100,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, patients: patients);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void upsertPatient(PatientSummary updated) {
    if (!mounted) return;
    final current = [...state.patients];
    final idx = current.indexWhere((p) => p.code == updated.code);
    if (idx >= 0) {
      current[idx] = updated;
    } else {
      current.insert(0, updated);
    }
    state = state.copyWith(patients: current);
  }
}

final doctorPatientsNotifierProvider =
    StateNotifierProvider<DoctorPatientsNotifier, DoctorPatientsState>((ref) {
      return DoctorPatientsNotifier(ref.watch(doctorPatientRepositoryProvider));
    });

/// Convenience: look up a single patient by caseId from the doctor cache.
final doctorPatientByIdProvider = Provider.family<PatientSummary?, String>(
  (ref, caseId) {
    return ref
        .watch(doctorPatientsNotifierProvider)
        .patients
        .where((p) => p.code == caseId)
        .cast<PatientSummary?>()
        .firstOrNull;
  },
);
