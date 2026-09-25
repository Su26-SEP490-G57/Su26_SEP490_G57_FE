import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';
import 'package:poms/features/patient/domain/repositories/diet_guidance_repository.dart';
import 'package:poms/features/patient/data/datasources/diet_guidance_remote_datasource.dart';

class DietGuidanceRepositoryImpl implements DietGuidanceRepository {
  const DietGuidanceRepositoryImpl(this._remoteDataSource);

  final DietGuidanceRemoteDataSource _remoteDataSource;

  @override
  Future<PodProtocolModel?> getCurrentDietGuidance(String caseId) async {
    // BE tự phân giải: ưu tiên chỉ định ăn riêng đang active của bác sĩ
    // (isCustomized = true), nếu không có mới trả về phác đồ chung theo POD.
    return _remoteDataSource.getCurrentDietGuidance(caseId);
  }
}
