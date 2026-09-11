import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/doctor/presentation/providers/doctor_patient_provider.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_patient_detail_page.dart';

/// Trang chi tiết bệnh nhân dành cho Bác sĩ.
/// Cung cấp đầy đủ các tính năng theo dõi tiến trình hồi phục, xem ma trận tuân thủ,
/// lịch sử đánh giá, ghi chú và các can thiệp lâm sàng tương tự điều dưỡng trên toàn bộ bệnh nhân.
class DoctorPatientDetailPage extends ConsumerWidget {
  const DoctorPatientDetailPage({
    required this.patientId,
    this.patient,
    super.key,
  });

  final String patientId;
  final PatientSummary? patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorPatients = ref.watch(doctorPatientsNotifierProvider);
    final doctorPatient = ref.watch(doctorPatientByIdProvider(patientId));
    final resolvedPatient = patient ?? doctorPatient;

    if (resolvedPatient == null && doctorPatients.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (resolvedPatient == null && doctorPatients.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            doctorPatients.errorMessage ?? 'Không thể tải hồ sơ người bệnh',
          ),
        ),
      );
    }

    return NursePatientDetailPage(
      patientId: patientId,
      patient: resolvedPatient,
      canManageDiet: true,
    );
  }
}
