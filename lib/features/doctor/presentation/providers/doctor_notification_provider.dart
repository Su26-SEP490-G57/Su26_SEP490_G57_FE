import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:poms/core/services/socket_service.dart';
import 'package:poms/features/doctor/data/datasources/doctor_notification_remote_datasource.dart';
import 'package:poms/features/doctor/domain/models/doctor_notification.dart';
import 'package:poms/main.dart';

final doctorNotificationRemoteDataSourceProvider =
    Provider<DoctorNotificationRemoteDataSource>((ref) {
      return DoctorNotificationRemoteDataSource(ref.watch(appDioProvider));
    });

final doctorNotificationsProvider =
    FutureProvider.autoDispose<List<DoctorNotification>>((ref) async {
      return ref
          .watch(doctorNotificationRemoteDataSourceProvider)
          .getNotifications();
    });

/// Reload when a nurse updates vital signs or manually pauses a diet level.
final doctorNotificationsRealtimeProvider = Provider.autoDispose<void>((ref) {
  final socket = SocketService(
    io.io(
      '${appFlavorConfig.apiBaseUrl}/patients',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    ),
  );

  socket.on('pod.locked', (_) => ref.invalidate(doctorNotificationsProvider));
  socket.on('vital_signs.created', (_) => ref.invalidate(doctorNotificationsProvider));
  socket.on('vital_signs.updated', (_) => ref.invalidate(doctorNotificationsProvider));
  unawaited(socket.connect());

  ref.onDispose(() {
    socket.off('pod.locked');
    socket.off('vital_signs.created');
    socket.off('vital_signs.updated');
    unawaited(socket.disconnect());
    socket.dispose();
  });
});
