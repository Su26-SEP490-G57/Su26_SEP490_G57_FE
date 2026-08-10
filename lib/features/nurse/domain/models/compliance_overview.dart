/// Tỷ lệ tuân thủ toàn khoa — dùng cho donut chart tổng quan.
class ComplianceOverview {
  const ComplianceOverview({
    required this.compliant,
    required this.nonCompliant,
    required this.complianceRate,
  });

  final int compliant;
  final int nonCompliant;
  final double complianceRate;

  int get total => compliant + nonCompliant;
}
