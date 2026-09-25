import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';

final assignedRoomsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final remote = ref.watch(patientRemoteDatasourceProvider);
  return remote.getAssignedRooms();
});

/// Điều dưỡng trưởng (và admin) phụ trách toàn khoa: xem MỌI người bệnh, không
/// phụ thuộc phòng được phân công — backend cũng chỉ giới hạn theo phòng với
/// điều dưỡng thường (GET /patients).
final canSeeAllPatientsProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(authNotifierProvider).user?.roles ?? const [];
  return roles.contains(UserRole.headNurse) || roles.contains(UserRole.admin);
});
