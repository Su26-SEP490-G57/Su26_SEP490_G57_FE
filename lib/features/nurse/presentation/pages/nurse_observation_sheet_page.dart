import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/presentation/widgets/care_sheets_list.dart';

/// Màn hình "Phiếu theo dõi và chăm sóc" của một người bệnh: danh sách phiếu
/// đã lưu ở HIS (mới nhất trước) + nút thêm phiếu cho điều dưỡng / điều dưỡng
/// trưởng. Loại phiếu (Cấp 1 / Cấp 2-3) theo mức chăm sóc bác sĩ chỉ định.
class NurseObservationSheetPage extends ConsumerWidget {
  const NurseObservationSheetPage({required this.caseId, super.key});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authNotifier rỗng khi phiên được khôi phục từ storage → fallback.
    final currentUser =
        ref.watch(authNotifierProvider).user ??
        ref.watch(authStateProvider).valueOrNull;
    final canCreate =
        currentUser?.primaryRole == UserRole.nurse ||
        currentUser?.primaryRole == UserRole.headNurse ||
        currentUser?.primaryRole == UserRole.doctor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Phiếu chăm sóc · $caseId',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CareSheetsList(caseId: caseId, canCreate: canCreate),
    );
  }
}
