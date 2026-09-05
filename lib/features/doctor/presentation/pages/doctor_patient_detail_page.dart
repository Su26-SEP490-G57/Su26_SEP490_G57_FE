import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

/// Trang chi tiết bệnh nhân cho bác sĩ.
/// TODO: Nhóm sẽ bổ sung các chức năng cụ thể của bác sĩ khi có task.
class DoctorPatientDetailPage extends StatelessWidget {
  const DoctorPatientDetailPage({
    required this.patientId,
    this.patient,
    super.key,
  });

  final String patientId;
  final PatientSummary? patient;

  @override
  Widget build(BuildContext context) {
    final displayName = patient?.name ?? patientId;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 72,
                color: Color(0xFFC2C6D8),
              ),
              const SizedBox(height: 16),
              Text(
                'Mã: $patientId',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424656),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chức năng chi tiết bệnh nhân dành cho bác sĩ\nđang được phát triển.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF727687),
                  height: 1.5,
                ),
              ),
              if (patient != null) ...[
                const SizedBox(height: 24),
                _InfoTile(label: 'Phòng', value: patient!.room),
                _InfoTile(label: 'POD', value: patient!.pod),
                _InfoTile(label: 'Trạng thái', value: patient!.status.label),
                if (patient!.surgeryType != null)
                  _InfoTile(label: 'Phẫu thuật', value: patient!.surgeryType!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424656),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF191B24),
            ),
          ),
        ],
      ),
    );
  }
}
