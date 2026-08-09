import 'package:poms/core/services/socket_service.dart';

import 'package:poms/features/nurse/data/models/patient_response.dart';

class PatientSocketDataSource {
  PatientSocketDataSource(this._socketService);

  final SocketService _socketService;

  Future<void> connect() async {
    await _socketService.connect();
  }

  Future<void> disconnect() async {
    await _socketService.disconnect();
  }

  void onPatientCreated(void Function(PatientResponse patient) callback) {
    _socketService.on('patient.created', (data) {
      callback(PatientResponse.fromJson(data));
    });
  }

  void onPatientUpdated(void Function(PatientResponse patient) callback) {
    _socketService.on('patient.updated', (data) {
      callback(PatientResponse.fromJson(data));
    });
  }

  void onPatientDeleted(void Function(String caseId) callback) {
    _socketService.on('patient.deleted', (data) {
      callback(data.toString());
    });
  }
}
