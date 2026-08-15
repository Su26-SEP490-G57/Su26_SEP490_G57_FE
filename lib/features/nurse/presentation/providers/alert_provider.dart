import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/alert_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/alert_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';
import 'package:poms/features/nurse/domain/repositories/alert_repository.dart';
import 'package:poms/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:poms/core/services/socket_service.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────

final alertRemoteDataSourceProvider = Provider<AlertRemoteDataSource>((ref) {
  final dio = ref.watch(appDioProvider);
  return AlertRemoteDataSource(dio);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final remoteDataSource = ref.watch(alertRemoteDataSourceProvider);
  return AlertRepositoryImpl(remoteDataSource);
});

// ── State ─────────────────────────────────────────────────────────────────────

class AlertsState {
  const AlertsState({
    this.alerts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AlertModel> alerts;
  final bool isLoading;
  final String? errorMessage;

  AlertsState copyWith({
    List<AlertModel>? alerts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier(this._repository) : super(const AlertsState()) {
    load();
  }

  final AlertRepository _repository;

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final raw = await _repository.getActiveAlerts();
      if (!mounted) return;
      // Deduplicate by caseId: keep only the newest alert per patient case.
      final byCase = <String, AlertModel>{};
      for (final alert in raw) {
        final existing = byCase[alert.caseId];
        if (existing == null) {
          byCase[alert.caseId] = alert;
        } else {
          final existingTime =
              existing.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final incomingTime =
              alert.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (incomingTime.isAfter(existingTime)) {
            byCase[alert.caseId] = alert;
          }
        }
      }
      // Sort newest-first across all cases.
      final deduped = byCase.values.toList()
        ..sort((a, b) {
          final ta = a.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
      state = state.copyWith(isLoading: false, alerts: deduped);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Upserts an alert:
  /// - If the same caseId already has an alert and the incoming one is NEWER,
  ///   replace it (keeps 1 alert per caseId — the latest).
  /// - If the incoming alert has a different caseId, add it.
  void upsertAlert(AlertModel incoming) {
    if (!mounted) return;

    final current = [...state.alerts];
    final existingIdx = current.indexWhere((a) => a.caseId == incoming.caseId);

    if (existingIdx >= 0) {
      final existing = current[existingIdx];
      final existingTime =
          existing.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final incomingTime =
          incoming.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      // Only overwrite if the incoming alert is newer or same.
      if (!incomingTime.isBefore(existingTime)) {
        current[existingIdx] = incoming;
      }
    } else {
      current.insert(0, incoming);
    }

    // Keep sorted: newest triggeredAt first across all cases.
    current.sort((a, b) {
      final ta = a.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.triggeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    state = state.copyWith(alerts: current);
  }

  /// Removes the alert for a given caseId.
  void removeAlertByCaseId(String caseId) {
    if (!mounted) return;
    state = state.copyWith(
      alerts: state.alerts.where((a) => a.caseId != caseId).toList(),
    );
  }

  /// Marks an alert as HANDLED in the in-memory list so the UI updates
  /// immediately after acknowledging without requiring a full reload.
  void markHandled(int alertId) {
    if (!mounted) return;
    final updated = state.alerts.map((a) {
      if (a.alertId == alertId) {
        return AlertModel(
          alertId: a.alertId,
          caseId: a.caseId,
          assessmentId: a.assessmentId,
          alertType: a.alertType,
          status: 'HANDLED',
          surveyScore: a.surveyScore,
          isAutoProgression: a.isAutoProgression,
          triggeredAt: a.triggeredAt,
          nurseAction: a.nurseAction,
          nursingNote: a.nursingNote,
          closedAt: a.closedAt,
        );
      }
      return a;
    }).toList();
    state = state.copyWith(alerts: updated);
  }
}

final alertsNotifierProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
      final repository = ref.watch(alertRepositoryProvider);
      return AlertsNotifier(repository);
    });

// ── Latest alert per caseId (what the UI actually shows) ─────────────────────

/// Returns a flat list where each element is the single most-recent alert
/// for a given caseId.  Because [AlertsNotifier.upsertAlert] already keeps
/// at most one entry per caseId in [AlertsState.alerts], this is essentially
/// a direct alias — but it makes the consumer intent explicit.
///
/// Sorted: newest triggeredAt first.
final latestAlertPerCaseProvider = Provider<List<AlertModel>>((ref) {
  return ref.watch(alertsNotifierProvider).alerts;
});

/// Fetches the active (PENDING_REVIEW) alert for a specific patient case.
/// Auto-disposes so that each page visit gets a fresh fetch.
final activeAlertForPatientProvider =
    FutureProvider.autoDispose.family<AlertModel?, String>((ref, caseId) async {
  final ds = ref.watch(alertRemoteDataSourceProvider);
  return ds.getActiveAlertByCaseId(caseId);
});

// ── Realtime alert socket provider ────────────────────────────────────────────

/// Watches the /statistics socket for alert events and upserts them into
/// [alertsNotifierProvider] automatically. Activate by calling
/// `ref.watch(alertRealtimeProvider)` once in the root widget.
final alertRealtimeProvider = Provider<void>((ref) {
  final socket = SocketService(
    io.io(
      '${appFlavorConfig.apiBaseUrl}/statistics',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    ),
  );

  AlertModel? parseAlert(dynamic payload) {
    try {
      Map<String, dynamic>? map;
      if (payload is Map<String, dynamic>) {
        map = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
      } else if (payload is Map) {
        map = payload.map((k, v) => MapEntry(k.toString(), v));
      }
      if (map == null) return null;
      return AlertModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void handleAlert(dynamic payload) {
    final alert = parseAlert(payload);
    if (alert == null) return;
    ref.read(alertsNotifierProvider.notifier).upsertAlert(alert);
  }

  socket.on('alert.created', handleAlert);
  socket.on('alert.updated', handleAlert);
  socket.on('alert.closed', handleAlert);

  // Connect/disconnect following auth state.
  final currentAuth = ref.read(authStateProvider);
  if (currentAuth.valueOrNull != null) {
    unawaited(socket.connect());
  }

  ref.listen<AsyncValue<dynamic>>(authStateProvider, (prev, next) {
    final wasAuth = prev?.valueOrNull != null;
    final isAuth = next.valueOrNull != null;
    if (isAuth) {
      unawaited(socket.connect());
    } else if (wasAuth && !isAuth) {
      unawaited(socket.disconnect());
    }
  });

  ref.onDispose(() {
    socket.off('alert.created');
    socket.off('alert.updated');
    socket.off('alert.closed');
    socket.dispose();
  });
});
