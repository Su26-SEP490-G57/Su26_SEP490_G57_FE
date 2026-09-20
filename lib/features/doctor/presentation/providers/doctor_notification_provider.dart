import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:poms/core/services/socket_service.dart';
import 'package:poms/features/doctor/data/datasources/doctor_notification_remote_datasource.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';
import 'package:poms/main.dart';

final doctorNotificationRemoteDataSourceProvider =
    Provider<DoctorNotificationRemoteDataSource>((ref) {
      return DoctorNotificationRemoteDataSource(ref.watch(appDioProvider));
    });

final doctorHandledAlertsProvider =
    FutureProvider.autoDispose<List<AlertModel>>((ref) async {
      return ref
          .watch(doctorNotificationRemoteDataSourceProvider)
          .getHandledAlerts();
    });

/// Reload the doctor's notification list as soon as a nurse handles an alert.
final doctorNotificationsRealtimeProvider = Provider.autoDispose<void>((ref) {
  final socket = SocketService(
    io.io(
      '${appFlavorConfig.apiBaseUrl}/alerts',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    ),
  );

  socket.on(
    'alert.handled',
    (_) => ref.invalidate(doctorHandledAlertsProvider),
  );
  unawaited(socket.connect());

  ref.onDispose(() {
    socket.off('alert.handled');
    unawaited(socket.disconnect());
    socket.dispose();
  });
});
