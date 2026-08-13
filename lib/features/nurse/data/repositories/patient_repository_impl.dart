import 'dart:async';

import 'package:poms/features/nurse/data/datasources/patient_remote_datasource.dart';
import 'package:poms/features/nurse/data/datasources/patient_socket_datasource.dart';
import 'package:poms/features/nurse/data/models/patient_response.dart';
import 'package:poms/features/nurse/domain/models/patient_page.dart';
import 'package:poms/features/nurse/domain/repositories/patient_repository.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._remote, this._socket);

  final PatientRemoteDataSource _remote;
  final PatientSocketDataSource _socket;

  final _createdController = StreamController<PatientSummary>.broadcast();
  final _updatedController = StreamController<PatientSummary>.broadcast();
  final _deletedController = StreamController<String>.broadcast();

  bool _initialized = false;

  @override
  Future<PatientPage> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _remote.getPatients(
      search: search,
      level: level,
      operationTypeId: operationTypeId,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      limit: limit,
    );

    return PatientPage(
      patients: response.data.map(_toSummary).toList(),
      total: response.total,
      page: response.page,
      limit: response.limit,
    );
  }

  @override
  Future<void> connectRealtime() async {
    if (_initialized) return;

    _registerSocketEvents();

    await _socket.connect();

    _initialized = true;
  }

  @override
  Future<void> disconnectRealtime() async {
    if (!_initialized) return;

    await _socket.disconnect();

    _initialized = false;
  }

  @override
  Stream<PatientSummary> createdPatients() {
    return _createdController.stream;
  }

  @override
  Stream<PatientSummary> updatedPatients() {
    return _updatedController.stream;
  }

  @override
  Stream<String> deletedPatients() {
    return _deletedController.stream;
  }

  void _registerSocketEvents() {
    _socket.onPatientCreated((patient) {
      _createdController.add(_toSummary(patient));
    });

    _socket.onPatientUpdated((patient) {
      _updatedController.add(_toSummary(patient));
    });

    _socket.onPatientDeleted((caseId) {
      _deletedController.add(caseId);
    });
  }

  PatientStatus _mapStatus(dynamic level) {
    if (level == null) {
      return PatientStatus.green;
    }

    final name = level['name']?.toString().toLowerCase();

    switch (name) {
      case 'red':
        return PatientStatus.red;

      case 'yellow':
        return PatientStatus.yellow;

      default:
        return PatientStatus.green;
    }
  }

  PatientSummary _toSummary(PatientResponse patient) {
    return PatientSummary(
      code: patient.caseId,
      name: patient.account.fullName,
      room: patient.roomBed ?? 'Chưa cập nhật',
      pod: 'POD ${patient.currentPod}',
      status: _mapStatus(patient.level),
      age: patient.age,
      gender: patient.gender,
      bmi: patient.bmi,
      surgeryDate: patient.surgeryDate,
      surgeryType: patient.operationType?.name,
      diagnosis: patient.diagnosis,
      operationTypeId: patient.operationType?.id,
      operationTypeName: patient.operationType?.name,
      operationMethod: patient.method,
      hasGiAnastomosis: patient.hasGiAnastomosis,
    );
  }
}
