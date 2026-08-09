import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/domain/repositories/patient_repository.dart';

import 'package:poms/features/nurse/presentation/providers/patient_state.dart';

class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier(this._repository) : super(const PatientState()) {
    _initialize();
  }

  final PatientRepository _repository;

  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;

    _initialized = true;

    await loadPatients();
  }

  Future<void> loadPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    if (!mounted) return;

    state = state.copyWith(status: PatientStatusState.loading);

    try {
      final result = await _repository.getPatients(
        search: search,
        level: level,
        operationTypeId: operationTypeId,
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
        limit: limit,
      );

      if (!mounted) return;

      state = state.copyWith(
        status: PatientStatusState.success,
        patients: result.patients,
        total: result.total,
        page: result.page,
        limit: result.limit,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        status: PatientStatusState.error,
        errorMessage: e.toString(),
      );
    }
  }

  void upsertPatient(PatientSummary patient) {
    if (!mounted) return;

    final index = state.patients.indexWhere((item) => item.code == patient.code);

    if (index < 0) {
      state = state.copyWith(
        patients: [patient, ...state.patients],
        total: state.total + 1,
      );
      return;
    }

    final patients = [...state.patients];
    patients[index] = patient;

    state = state.copyWith(patients: patients);
  }

  void patchPatient(
    String caseId, {
    String? name,
    String? room,
    String? pod,
    PatientStatus? status,
    int? age,
    String? gender,
    String? surgeryDate,
    String? pathway,
    double? bmi,
    String? surgeryType,
    String? diagnosis,
    int? operationTypeId,
    String? operationTypeName,
    String? operationMethod,
    bool? hasGiAnastomosis,
    String? nurseInCharge,
    String? doctorInCharge,
    int? alertCount,
    int? assessmentDone,
    int? assessmentTotal,
    String? lastAssessmentTime,
    bool? needsIntervention,
  }) {
    if (!mounted) return;

    final patients = state.patients.map((item) {
      if (item.code != caseId) {
        return item;
      }

      return item.copyWith(
        name: name,
        room: room,
        pod: pod,
        status: status,
        age: age,
        gender: gender,
        surgeryDate: surgeryDate,
        pathway: pathway,
        bmi: bmi,
        surgeryType: surgeryType,
        diagnosis: diagnosis,
        operationTypeId: operationTypeId,
        operationTypeName: operationTypeName,
        operationMethod: operationMethod,
        hasGiAnastomosis: hasGiAnastomosis,
        nurseInCharge: nurseInCharge,
        doctorInCharge: doctorInCharge,
        alertCount: alertCount,
        assessmentDone: assessmentDone,
        assessmentTotal: assessmentTotal,
        lastAssessmentTime: lastAssessmentTime,
        needsIntervention: needsIntervention,
      );
    }).toList();

    state = state.copyWith(patients: patients);
  }

  void removePatient(String caseId) {
    if (!mounted) return;

    final exists = state.patients.any((e) => e.code == caseId);
    if (!exists) return;

    final patients = state.patients.where((e) => e.code != caseId).toList();

    state = state.copyWith(
      patients: patients,
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }
}
