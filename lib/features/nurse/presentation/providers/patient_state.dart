import 'package:poms/features/nurse/domain/models/patient_summary.dart';

enum PatientStatusState { initial, loading, success, error }

class PatientState {
  const PatientState({
    this.status = PatientStatusState.initial,
    this.patients = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 10,
    this.errorMessage,
  });

  final PatientStatusState status;
  final List<PatientSummary> patients;
  final int total;
  final int page;
  final int limit;
  final String? errorMessage;
  bool get isLoading => status == PatientStatusState.loading;
  bool get hasError => status == PatientStatusState.error;
  bool get isSuccess => status == PatientStatusState.success;

  PatientState copyWith({
    PatientStatusState? status,
    List<PatientSummary>? patients,
    int? total,
    int? page,
    int? limit,
    String? errorMessage,
  }) {
    return PatientState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
