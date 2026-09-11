import 'package:flutter/material.dart';

import 'package:poms/core/constants/app_colors.dart';

/// Reserved read-only area for clinical documents attached to a patient case.
/// Mobile will consume the document list once its API contract is finalized.
class MedicalRecordsTab extends StatelessWidget {
  const MedicalRecordsTab({required this.caseId, super.key});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          'Bệnh án',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: const Color(0xFF191B24),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tài liệu lâm sàng của người bệnh được lưu theo từng hồ sơ.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF727687),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC2C6D8)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.folder_shared_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có tài liệu bệnh án',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191B24),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Phiếu phẫu thuật, phiếu theo dõi chăm sóc và phiếu theo dõi điều trị sẽ hiển thị tại đây khi được cập nhật cho hồ sơ này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF727687),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Mã hồ sơ: $caseId',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
