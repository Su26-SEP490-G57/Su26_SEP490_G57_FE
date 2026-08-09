import 'package:socket_io_client/socket_io_client.dart';

class SocketService {
  SocketService(this._socket);

  final Socket _socket;

  Future<void> connect() async {
    if (_socket.connected) return;

    _socket.connect();
  }

  Future<void> disconnect() async {
    if (!_socket.connected) return;

    _socket.disconnect();
  }

  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket.on(event, handler);
  }

  void off(String event) {
    _socket.off(event);
  }

  void dispose() {
    _socket.dispose();
  }
}