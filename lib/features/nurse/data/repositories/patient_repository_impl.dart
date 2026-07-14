import '../../domain/models/patient_summary.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource _remoteDataSource;

  PatientRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PatientSummary>> getPatients({
    String? search,
    String? level,
    int? operationTypeId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _remoteDataSource.getPatients(
      search: search,
      level: level,
      operationTypeId: operationTypeId,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      limit: limit,
    );

    final dataList = response['data'] as List<dynamic>? ?? [];

    return dataList.map((item) {
      final map = item as Map<String, dynamic>;
      final account = map['account'] as Map<String, dynamic>?;
      final levelObj = map['level'] as Map<String, dynamic>?;

      // Map level string to enum
      PatientStatus status = PatientStatus.green;
      if (levelObj != null) {
        final levelName = (levelObj['name'] as String?)?.toUpperCase();
        if (levelName == 'RED') status = PatientStatus.red;
        if (levelName == 'YELLOW') status = PatientStatus.yellow;
      }

      return PatientSummary(
        code: map['case_id'] as String? ?? 'UNKNOWN',
        name: account?['fullName'] as String? ?? 'Chưa cập nhật',
        room: map['room_bed'] as String? ?? 'Chưa xếp phòng',
        pod: 'POD ${map['current_pod'] ?? '?'}',
        status: status,
      );
    }).toList();
  }
}
