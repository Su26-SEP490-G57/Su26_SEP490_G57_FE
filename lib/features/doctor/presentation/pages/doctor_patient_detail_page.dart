import 'package:flutter/material.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/pages/nurse_patient_detail_page.dart';

/// Trang chi tiết bệnh nhân dành cho Bác sĩ.
/// Cung cấp đầy đủ các tính năng theo dõi tiến trình hồi phục, xem ma trận tuân thủ,
/// lịch sử đánh giá, ghi chú và các can thiệp lâm sàng tương tự điều dưỡng trên toàn bộ bệnh nhân.
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
    return NursePatientDetailPage(
      patientId: patientId,
      patient: patient,
    );
  }
}
