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

final doctorPatientRepositoryProvider = Provider<DoctorPatientRepository>((
  ref,
) {
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
  DoctorPatientsNotifier(this._repository)
    : super(const DoctorPatientsState()) {
    loadPatients();
  }

  final DoctorPatientRepository _repository;

  Future<void> loadPatients({String? search}) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final patients = await _repository.getAllPatients(
        search: search,
        // A doctor sees the complete ward roster. UI pagination is handled
        // locally, so fetch the full in-scope list instead of a partial page.
        limit: 1000,
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
    state = state.copyWith(patients: _sortedByPriority(current));
  }

  void removePatient(String caseId) {
    if (!mounted) return;
    final exists = state.patients.any((p) => p.code == caseId);
    if (!exists) return;
    state = state.copyWith(
      patients: state.patients.where((p) => p.code != caseId).toList(),
    );
  }

  /// Cập nhật 1 phần dữ liệu (vd triage color sau khi nộp/đánh giá lại) —
  /// mirror `PatientNotifier.patchPatient` bên nurse, để danh sách bệnh nhân
  /// của doctor cũng cập nhật realtime qua socket giống hệt bên nurse thay vì
  /// chỉ đọc 1 lần lúc mở màn.
  void patchPatient(
    String caseId, {
    PatientStatus? status,
    String? lastAssessmentTime,
    int? assessmentDone,
    bool? needsIntervention,
    int? alertCount,
  }) {
    if (!mounted) return;
    final patients = state.patients.map((item) {
      if (item.code != caseId) return item;
      return item.copyWith(
        status: status,
        lastAssessmentTime: lastAssessmentTime,
        assessmentDone: assessmentDone,
        needsIntervention: needsIntervention,
        alertCount: alertCount,
      );
    }).toList();
    // Re-sort so priority order (ĐỎ → VÀNG → XANH) stays correct after a
    // WebSocket reassessment event changes a patient's triage status —
    // mirrors PatientNotifier.patchPatient on the nurse side.
    state = state.copyWith(patients: _sortedByPriority(patients));
  }

  /// Sort patients ĐỎ → VÀNG → XANH, preserving relative order within each group.
  static List<PatientSummary> _sortedByPriority(List<PatientSummary> list) {
    const rank = {
      PatientStatus.red: 0,
      PatientStatus.yellow: 1,
      PatientStatus.green: 2,
    };
    return [...list]
      ..sort((a, b) => (rank[a.status] ?? 2).compareTo(rank[b.status] ?? 2));
  }
}

final doctorPatientsNotifierProvider =
    StateNotifierProvider<DoctorPatientsNotifier, DoctorPatientsState>((ref) {
      return DoctorPatientsNotifier(ref.watch(doctorPatientRepositoryProvider));
    });

/// Convenience: look up a single patient by caseId from the doctor cache.
final doctorPatientByIdProvider = Provider.family<PatientSummary?, String>((
  ref,
  caseId,
) {
  return ref
      .watch(doctorPatientsNotifierProvider)
      .patients
      .where((p) => p.code == caseId)
      .cast<PatientSummary?>()
      .firstOrNull;
});
