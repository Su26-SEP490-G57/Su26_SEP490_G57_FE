import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/core/services/socket_provider.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

import 'package:poms/features/nurse/data/datasources/patient_remote_datasource.dart';
import 'package:poms/features/nurse/data/datasources/patient_socket_datasource.dart';
import 'package:poms/features/nurse/data/repositories/patient_repository_impl.dart';

import 'package:poms/features/nurse/domain/repositories/patient_repository.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/domain/models/patient_pod_status.dart';

import 'package:poms/features/nurse/presentation/providers/patient_notifier.dart';
import 'package:poms/features/nurse/presentation/providers/patient_state.dart';

final patientRemoteDatasourceProvider = Provider<PatientRemoteDataSource>((
  ref,
) {
  return PatientRemoteDataSource(ref.watch(appDioProvider));
});

final patientSocketDatasourceProvider = Provider<PatientSocketDataSource>((
  ref,
) {
  return PatientSocketDataSource(ref.watch(socketServiceProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl(
    ref.watch(patientRemoteDatasourceProvider),
    ref.watch(patientSocketDatasourceProvider),
  );
});

final patientNotifierProvider =
    StateNotifierProvider<PatientNotifier, PatientState>((ref) {
      return PatientNotifier(ref.watch(patientRepositoryProvider));
    });

final patientPodStatusProvider = FutureProvider.autoDispose
    .family<PatientPodStatus, String>((ref, caseId) async {
      return ref.watch(patientRemoteDatasourceProvider).getPodStatus(caseId);
    });

final patientByIdProvider = Provider.family<PatientSummary?, String>((
  ref,
  caseId,
) {
  final snapshot = ref.watch(
    patientNotifierProvider.select((state) {
      final patient = state.patients
          .where((item) => item.code == caseId)
          .cast<PatientSummary?>()
          .firstOrNull;

      if (patient == null) {
        return null;
      }

      return (
        code: patient.code,
        name: patient.name,
        room: patient.room,
        pod: patient.pod,
        status: patient.status,
        age: patient.age,
        gender: patient.gender,
        surgeryDate: patient.surgeryDate,
        pathway: patient.pathway,
        bmi: patient.bmi,
        surgeryType: patient.surgeryType,
        diagnosis: patient.diagnosis,
        operationTypeId: patient.operationTypeId,
        operationTypeName: patient.operationTypeName,
        operationMethod: patient.operationMethod,
        hasGiAnastomosis: patient.hasGiAnastomosis,
        nurseInCharge: patient.nurseInCharge,
        doctorInCharge: patient.doctorInCharge,
        alertCount: patient.alertCount,
        assessmentDone: patient.assessmentDone,
        assessmentTotal: patient.assessmentTotal,
        lastAssessmentTime: patient.lastAssessmentTime,
        needsIntervention: patient.needsIntervention,
        dietLevel: patient.dietLevel,
      );
    }),
  );

  if (snapshot == null) {
    return null;
  }

  return PatientSummary(
    code: snapshot.code,
    name: snapshot.name,
    room: snapshot.room,
    pod: snapshot.pod,
    status: snapshot.status,
    age: snapshot.age,
    gender: snapshot.gender,
    surgeryDate: snapshot.surgeryDate,
    pathway: snapshot.pathway,
    bmi: snapshot.bmi,
    surgeryType: snapshot.surgeryType,
    diagnosis: snapshot.diagnosis,
    operationTypeId: snapshot.operationTypeId,
    operationTypeName: snapshot.operationTypeName,
    operationMethod: snapshot.operationMethod,
    hasGiAnastomosis: snapshot.hasGiAnastomosis,
    nurseInCharge: snapshot.nurseInCharge,
    doctorInCharge: snapshot.doctorInCharge,
    alertCount: snapshot.alertCount,
    assessmentDone: snapshot.assessmentDone,
    assessmentTotal: snapshot.assessmentTotal,
    lastAssessmentTime: snapshot.lastAssessmentTime,
    needsIntervention: snapshot.needsIntervention,
    dietLevel: snapshot.dietLevel,
  );
});
