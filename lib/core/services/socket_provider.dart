import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:poms/core/services/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final socket = io.io(
    '${appFlavorConfig.apiBaseUrl}/patients',
    io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

  final service = SocketService(socket);

  ref.onDispose(service.dispose);

  return service;
});
