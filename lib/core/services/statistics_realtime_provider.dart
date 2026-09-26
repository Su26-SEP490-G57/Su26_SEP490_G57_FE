import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/core/services/socket_service.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/doctor/presentation/providers/doctor_patient_provider.dart';
import 'package:poms/features/nurse/data/models/patient_response.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/analytics_provider.dart';
import 'package:poms/features/nurse/presentation/providers/assessment_provider.dart'
    as nurse_assessment;
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';
import 'package:poms/features/nurse/presentation/providers/priority_patients_provider.dart';
import 'package:poms/features/patient/domain/models/patient_notification_model.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';
import 'package:poms/features/patient/presentation/providers/patient_notification_provider.dart';
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

  // Khoá/mở mức ăn (nút "Tạm dừng ăn"/"Tiếp tục ăn") phát trên namespace
  // RIÊNG '/patients' (PatientGateway), không đi qua '/statistics' — cần kết
  // nối thêm để 1 phiên nurse/doctor khác (hoặc chính patient đó) thấy ngay
  // không cần reload.
  final patientsSocket = SocketService(
    io.io(
      '${appFlavorConfig.apiBaseUrl}/patients',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    ),
  );

  Future<void> connectIfNeeded() async {
    await socket.connect();
    await patientsSocket.connect();
  }

  Future<void> disconnectIfNeeded() async {
    await socket.disconnect();
    await patientsSocket.disconnect();
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

  // Doctor có danh sách bệnh nhân RIÊNG (doctorPatientsNotifierProvider,
  // không autoDispose) — trước giờ chỉ fetch 1 lần lúc mở màn, không có
  // realtime nào cả nên hay bị lệch so với bên nurse. Chỉ đọc/tạo provider
  // này khi người đang đăng nhập THẬT SỰ là doctor, tránh việc mọi session
  // (kể cả nurse/patient) đều vô tình fetch nguyên danh sách bệnh nhân của
  // doctor mỗi lần có socket event.
  bool isCurrentUserDoctor() =>
      ref.read(authStateProvider).valueOrNull?.primaryRole == UserRole.doctor;

  void applyPatientPayload(dynamic payload) {
    final patient = patientFromPayload(payload);
    if (patient == null) return;

    ref.read(patientNotifierProvider.notifier).upsertPatient(patient);
    if (isCurrentUserDoctor()) {
      ref.read(doctorPatientsNotifierProvider.notifier).upsertPatient(patient);
    }
  }

  void removePatientPayload(dynamic payload) {
    final map = extractMap(payload);
    final caseId = map?['caseId']?.toString() ?? payload?.toString();
    if (caseId == null || caseId.isEmpty) return;

    ref.read(patientNotifierProvider.notifier).removePatient(caseId);
    if (isCurrentUserDoctor()) {
      ref.read(doctorPatientsNotifierProvider.notifier).removePatient(caseId);
    }
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

    if (isCurrentUserDoctor()) {
      final existingForDoctor = ref
          .read(doctorPatientsNotifierProvider)
          .patients
          .where((item) => item.code == caseId)
          .cast<PatientSummary?>()
          .firstOrNull;

      ref
          .read(doctorPatientsNotifierProvider.notifier)
          .patchPatient(
            caseId,
            status: status,
            lastAssessmentTime: lastAssessmentTime,
            assessmentDone: existingForDoctor != null
                ? existingForDoctor.assessmentDone + 1
                : null,
            needsIntervention: status == PatientStatus.red,
            alertCount: status == PatientStatus.red
                ? (existingForDoctor?.alertCount ?? 0) + 1
                : existingForDoctor?.alertCount,
          );
    }

    ref.invalidate(nurse_assessment.assessmentNotifierProvider(caseId));
    ref.invalidate(currentPodProvider);
    ref.invalidate(patient_survey.surveyQuestionsProvider);
  }

  // Thông báo mới cho chính bệnh nhân đang đăng nhập (vd bác sĩ đổi chế độ
  // ăn Chung/Riêng) — cập nhật ngay khi app đang mở, không cần đợi FCM (không
  // chạy được trên simulator, và OS có thể trì hoãn khi thiết bị thật).
  void applyNotificationPayload(dynamic payload) {
    final map = extractMap(payload);
    if (map == null) return;

    final myCaseId = ref.read(authStateProvider).valueOrNull?.caseId;
    final eventCaseId = map['caseId']?.toString();
    if (myCaseId == null || eventCaseId == null || eventCaseId != myCaseId) {
      return;
    }

    try {
      final notification = PatientNotificationModel.fromJson(map);
      ref
          .read(patientNotificationsNotifierProvider.notifier)
          .upsertFromSocket(notification);
    } catch (_) {
      // Payload không đúng dạng mong đợi — bỏ qua, không làm crash socket listener.
    }
  }

  // Bất kỳ ai (nurse/doctor khác, hoặc chính patient) đang xem patient này
  // đều cần thấy trạng thái khoá mức ăn mới ngay, không cần reload.
  void applyPodLockPayload(dynamic payload) {
    final map = extractMap(payload);
    final caseId = map?['caseId']?.toString();
    if (caseId == null || caseId.isEmpty) return;

    ref.invalidate(patientPodStatusProvider(caseId));

    final myCaseId = ref.read(authStateProvider).valueOrNull?.caseId;
    if (myCaseId != null && myCaseId == caseId) {
      ref.invalidate(currentPodProvider);
    }
  }

  patientsSocket.on('pod.locked', applyPodLockPayload);
  patientsSocket.on('pod.unlocked', applyPodLockPayload);

  socket.on('notification.created', applyNotificationPayload);

  socket.on('createPatient', (payload) {
    applyPatientPayload(payload);
    ref.invalidate(priorityPatientsProvider);
    ref.invalidate(complianceOverviewProvider);
  });

  socket.on('updatePatient', (payload) {
    applyPatientPayload(payload);
    ref.invalidate(priorityPatientsProvider);
  });

  socket.on('deletePatient', (payload) {
    removePatientPayload(payload);
    ref.invalidate(priorityPatientsProvider);
    ref.invalidate(complianceOverviewProvider);
  });

  socket.on('submitSurvey', (payload) {
    applySurveyPayload(payload);
    ref.invalidate(priorityPatientsProvider);
    // Invalidate compliance overview so Dashboard updates the donut chart live.
    ref.invalidate(complianceOverviewProvider);
  });

  socket.on('assessment.submitted', (payload) {
    applySurveyPayload(payload);
    ref.invalidate(priorityPatientsProvider);
    // Invalidate compliance overview so Dashboard updates the donut chart live.
    ref.invalidate(complianceOverviewProvider);
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
    socket.off('notification.created');
    socket.dispose();
    patientsSocket.off('pod.locked');
    patientsSocket.off('pod.unlocked');
    patientsSocket.dispose();
  });
});
