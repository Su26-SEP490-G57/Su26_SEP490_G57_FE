import 'package:poms/features/nurse/domain/models/patient_compliance_summary.dart';

/// Trang kết quả phân trang của GET /patients/analytics/compliance-list.
class PatientComplianceListPage {
  const PatientComplianceListPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PatientComplianceSummary> items;
  final int total;
  final int page;
  final int limit;

  int get totalPages =>
      total == 0 ? 1 : (total / limit).ceil().clamp(1, 1 << 30);
}
