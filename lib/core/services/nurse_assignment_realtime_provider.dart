import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:poms/core/services/socket_service.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/presentation/providers/assigned_rooms_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';
import 'package:poms/main.dart';

/// Reloads each signed-in nurse's own room scope after the head-nurse web app
/// changes assignments. The WebSocket event has no assignment payload; access
/// control remains with the authenticated REST endpoints.
final nurseAssignmentRealtimeProvider = Provider<void>((ref) {
  final socket = SocketService(
    io.io(
      '${appFlavorConfig.apiBaseUrl}/nurses',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    ),
  );

  void handleRoomAssignmentsChanged(dynamic _) {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    final isNurse = currentUser?.roles.contains(UserRole.nurse) ?? false;
    if (!isNurse) return;

    ref.invalidate(assignedRoomsProvider);
    unawaited(
      ref.read(patientNotifierProvider.notifier).refreshAssignedPatients(),
    );
  }

  Future<void> connectIfAuthenticated() async {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser?.roles.contains(UserRole.nurse) != true) return;
    await socket.connect();
  }

  socket.on('nurse.rooms.changed', handleRoomAssignmentsChanged);
  unawaited(connectIfAuthenticated());

  ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
    final wasAuthenticated = previous?.valueOrNull != null;
    final isAuthenticated = next.valueOrNull != null;

    if (isAuthenticated) {
      unawaited(connectIfAuthenticated());
    } else if (wasAuthenticated) {
      unawaited(socket.disconnect());
    }
  });

  ref.onDispose(() {
    socket.off('nurse.rooms.changed');
    socket.dispose();
  });
});
