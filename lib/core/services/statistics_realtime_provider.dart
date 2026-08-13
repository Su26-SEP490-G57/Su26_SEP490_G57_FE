import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/core/services/socket_service.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/models/patient_response.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/assessment_provider.dart'
    as nurse_assessment;
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';
import 'package:poms/features/nurse/presentation/providers/priority_patients_provider.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';
import 'package:poms/features/patient/presentation/providers/survey_provider.dart'
    as patient_survey;
import 'package:poms/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final statisticsRealtimeProvider = Provider<void>((ref) {
  String? lastSurveyEventKey;

  final socket = SocketService(
    io.io(
      '${appFlavorConfig.apiBaseUrl}/statistics',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    ),
  );

  Future<void> connectIfNeeded() async {
    await socket.connect();
  }

  Future<void> disconnectIfNeeded() async {
    await socket.disconnect();
    lastSurveyEventKey = null;
  }

  Map<String, dynamic>? extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final nested = payload['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }

      final patient = payload['patient'];
      if (patient is Map<String, dynamic>) {
        return patient;
      }

      return payload;
    }

    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  PatientStatus? mapPatientStatus(dynamic triageColor) {
    if (triageColor == null) return null;

    return switch (triageColor.toString().toUpperCase()) {
      'RED' => PatientStatus.red,
      'YELLOW' => PatientStatus.yellow,
      'GREEN' => PatientStatus.green,
      _ => null,
    };
  }

  PatientSummary? patientFromPayload(dynamic payload) {
    final map = extractMap(payload);
    if (map == null) return null;

    try {
      final response = PatientResponse.fromJson(map);
      return PatientSummary(
        code: response.caseId,
        name: response.account.fullName,
        room: response.roomBed ?? 'Chưa cập nhật',
        pod: 'POD ${response.currentPod}',
        status: mapPatientStatus(response.level) ?? PatientStatus.green,
        age: response.age,
        gender: response.gender,
        bmi: response.bmi,
        surgeryDate: response.surgeryDate,
        surgeryType: response.operationType?.name,
        diagnosis: response.diagnosis,
        operationTypeId: response.operationType?.id,
        operationTypeName: response.operationType?.name,
        operationMethod: response.method,
        hasGiAnastomosis: response.hasGiAnastomosis,
      );
    } catch (_) {
      return null;
    }
  }

  void applyPatientPayload(dynamic payload) {
    final patient = patientFromPayload(payload);
    if (patient == null) return;

    ref.read(patientNotifierProvider.notifier).upsertPatient(patient);
  }

  void removePatientPayload(dynamic payload) {
    final map = extractMap(payload);
    final caseId = map?['caseId']?.toString() ?? payload?.toString();
    if (caseId == null || caseId.isEmpty) return;

    ref.read(patientNotifierProvider.notifier).removePatient(caseId);
  }

  void applySurveyPayload(dynamic payload) {
    final map = extractMap(payload);
    final caseId = map?['caseId']?.toString();
    if (caseId == null || caseId.isEmpty) return;

    final surveyEventKey =
        map?['assessmentId']?.toString() ??
        map?['assessment_id']?.toString() ??
        '${caseId}_${map?['totalScore'] ?? map?['total_score'] ?? ''}_${map?['triageColor'] ?? map?['triage_color'] ?? ''}';

    if (lastSurveyEventKey == surveyEventKey) {
      return;
    }

    lastSurveyEventKey = surveyEventKey;
    scheduleMicrotask(() => lastSurveyEventKey = null);

    final patientNotifier = ref.read(patientNotifierProvider.notifier);
    final status = mapPatientStatus(map?['triageColor']);
    final lastAssessmentTime =
        map?['evaluationDatetime']?.toString() ??
        map?['createdAt']?.toString() ??
        DateTime.now().toIso8601String();

    final existing = ref
        .read(patientNotifierProvider)
        .patients
        .where((item) => item.code == caseId)
        .cast<PatientSummary?>()
        .firstOrNull;

    patientNotifier.patchPatient(
      caseId,
      status: status,
      lastAssessmentTime: lastAssessmentTime,
      assessmentDone: existing != null ? existing.assessmentDone + 1 : null,
      needsIntervention: status == PatientStatus.red,
      alertCount: status == PatientStatus.red
          ? (existing?.alertCount ?? 0) + 1
          : existing?.alertCount,
    );

    ref.invalidate(nurse_assessment.assessmentNotifierProvider(caseId));
    ref.invalidate(currentPodProvider);
    ref.invalidate(patient_survey.surveyQuestionsProvider);
  }

  socket.on('createPatient', (payload) {
    applyPatientPayload(payload);
    ref.invalidate(priorityPatientsProvider);
  });

  socket.on('updatePatient', (payload) {
    applyPatientPayload(payload);
    ref.invalidate(priorityPatientsProvider);
  });

  socket.on('deletePatient', (payload) {
    removePatientPayload(payload);
    ref.invalidate(priorityPatientsProvider);
  });

  socket.on('submitSurvey', (payload) {
    applySurveyPayload(payload);
    ref.invalidate(priorityPatientsProvider);
  });

  socket.on('assessment.submitted', (payload) {
    applySurveyPayload(payload);
    ref.invalidate(priorityPatientsProvider);
  });

  final currentAuth = ref.read(authStateProvider);
  if (currentAuth.valueOrNull != null) {
    unawaited(connectIfNeeded());
  }

  ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
    final wasAuthenticated = previous?.valueOrNull != null;
    final isAuthenticated = next.valueOrNull != null;

    if (isAuthenticated) {
      unawaited(connectIfNeeded());
      return;
    }

    if (wasAuthenticated && !isAuthenticated) {
      unawaited(disconnectIfNeeded());
    }
  });

  ref.onDispose(() {
    socket.off('createPatient');
    socket.off('updatePatient');
    socket.off('deletePatient');
    socket.off('submitSurvey');
    socket.off('assessment.submitted');
    socket.dispose();
  });
});
