import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';

final assignedRoomsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final remote = ref.watch(patientRemoteDatasourceProvider);
  return remote.getAssignedRooms();
});
