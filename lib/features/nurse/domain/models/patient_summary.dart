import 'package:flutter/material.dart';

/// Mức độ cảnh báo
enum PatientStatus { red, yellow, green }

extension PatientStatusX on PatientStatus {
  String get label => switch (this) {
    PatientStatus.red => 'ĐỎ',
    PatientStatus.yellow => 'VÀNG',
    PatientStatus.green => 'XANH',
  };

  Color get badgeBg => switch (this) {
    PatientStatus.red => const Color(0x1ABA1A1A),
    PatientStatus.yellow => const Color(0x1AA33200),
    PatientStatus.green => const Color(0x1A006A61),
  };

  Color get badgeText => switch (this) {
    PatientStatus.red => const Color(0xFFBA1A1A),
    PatientStatus.yellow => const Color(0xFFA33200),
    PatientStatus.green => const Color(0xFF006A61),
  };

  /// Màu nền solid dùng trong hero (trên nền primary)
  Color get solidBg => switch (this) {
    PatientStatus.red => const Color(0xFFBA1A1A),
    PatientStatus.yellow => const Color(0xFFA33200),
    PatientStatus.green => const Color(0xFF006A61),
  };

  /// Icon trạng thái tim
  Color get dotColor => switch (this) {
    PatientStatus.red => const Color(0xFFBA1A1A),
    PatientStatus.yellow => const Color(0xFFA33200),
    PatientStatus.green => const Color(0xFF006A61),
  };
}

/// Model tóm tắt bệnh nhân — dùng chung giữa list và detail
class PatientSummary {
  const PatientSummary({
    required this.code,
    required this.name,
    required this.room,
    required this.pod,
    required this.status,
    this.age,
    this.gender,
    this.surgeryDate,
    this.pathway,
    this.bmi,
    this.surgeryType,
    this.diagnosis,
    this.operationTypeId,
    this.operationTypeName,
    this.operationMethod,
    this.hasGiAnastomosis,
    this.nurseInCharge,
    this.doctorInCharge,
    this.alertCount = 0,
    this.assessmentDone = 0,
    this.assessmentTotal = 0,
    this.lastAssessmentTime,
    this.needsIntervention = false,
  });

  // ── List fields ──────────────────────────────────────────────────
  final String code;
  final String name;
  final String room;
  final String pod;
  final PatientStatus status;

  // ── Detail fields ────────────────────────────────────────────────
  final int? age;
  final String? gender;
  final String? surgeryDate;
  final String? pathway;
  final double? bmi;
  final String? surgeryType;
  final String? diagnosis;
  final int? operationTypeId;
  final String? operationTypeName;
  final String? operationMethod;
  final bool? hasGiAnastomosis;
  final String? nurseInCharge;
  final String? doctorInCharge;
  final int alertCount;
  final int assessmentDone;
  final int assessmentTotal;
  final String? lastAssessmentTime;
  final bool needsIntervention;

  /// POD number chỉ (vd: "POD 2" → "2")
  String get podNumber => pod.replaceAll(RegExp(r'[^0-9]'), '');
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock data — thay bằng API call khi BE sẵn sàng
// ─────────────────────────────────────────────────────────────────────────────

const kMockPatients = [
  PatientSummary(
    code: 'BN001',
    name: 'Nguyễn Văn A',
    room: 'Buồng 305 - Giường 01',
    pod: 'POD 2',
    status: PatientStatus.red,
    age: 58,
    gender: 'Nam',
    surgeryDate: '10/05/2025',
    pathway: 'Gastric pathway',
    bmi: 22.1,
    surgeryType: 'Dạ dày',
    nurseInCharge: 'ĐD. Nguyễn Thị Hoa',
    doctorInCharge: 'BS. Trần Văn Nam',
    alertCount: 1,
    assessmentDone: 2,
    assessmentTotal: 2,
    lastAssessmentTime: '12/05/2025 08:20',
    needsIntervention: true,
  ),
  PatientSummary(
    code: 'BN002',
    name: 'Trần Thị B',
    room: 'Buồng 306 - Giường 02',
    pod: 'POD 1',
    status: PatientStatus.yellow,
    age: 45,
    gender: 'Nữ',
    surgeryDate: '11/05/2025',
    pathway: 'Colorectal pathway',
    bmi: 24.3,
    surgeryType: 'Đại tràng',
    nurseInCharge: 'ĐD. Nguyễn Thị Hoa',
    doctorInCharge: 'BS. Trần Văn Nam',
    alertCount: 0,
    assessmentDone: 1,
    assessmentTotal: 2,
    lastAssessmentTime: '12/05/2025 07:00',
    needsIntervention: false,
  ),
  PatientSummary(
    code: 'BN003',
    name: 'Lê Văn C',
    room: 'Buồng 303 - Giường 03',
    pod: 'POD 2',
    status: PatientStatus.green,
    age: 62,
    gender: 'Nam',
    surgeryDate: '10/05/2025',
    pathway: 'Hepatobiliary pathway',
    bmi: 21.8,
    surgeryType: 'Gan mật',
    nurseInCharge: 'ĐD. Lê Thị Mai',
    doctorInCharge: 'BS. Phạm Văn Hùng',
    alertCount: 0,
    assessmentDone: 2,
    assessmentTotal: 2,
    lastAssessmentTime: '12/05/2025 06:30',
    needsIntervention: false,
  ),
  PatientSummary(
    code: 'BN004',
    name: 'Phạm Văn D',
    room: 'Buồng 304 - Giường 01',
    pod: 'POD 1',
    status: PatientStatus.green,
    age: 50,
    gender: 'Nam',
    surgeryDate: '11/05/2025',
    pathway: 'Gastric pathway',
    bmi: 23.5,
    surgeryType: 'Dạ dày',
    nurseInCharge: 'ĐD. Lê Thị Mai',
    doctorInCharge: 'BS. Phạm Văn Hùng',
    alertCount: 0,
    assessmentDone: 1,
    assessmentTotal: 1,
    lastAssessmentTime: '12/05/2025 08:00',
    needsIntervention: false,
  ),
  PatientSummary(
    code: 'BN005',
    name: 'Hoàng Thị E',
    room: 'Buồng 302 - Giường 02',
    pod: 'POD 3',
    status: PatientStatus.green,
    age: 38,
    gender: 'Nữ',
    surgeryDate: '09/05/2025',
    pathway: 'Colorectal pathway',
    bmi: 20.4,
    surgeryType: 'Đại tràng',
    nurseInCharge: 'ĐD. Nguyễn Thị Hoa',
    doctorInCharge: 'BS. Trần Văn Nam',
    alertCount: 0,
    assessmentDone: 3,
    assessmentTotal: 3,
    lastAssessmentTime: '12/05/2025 07:45',
    needsIntervention: false,
  ),
  PatientSummary(
    code: 'BN006',
    name: 'Vũ Văn F',
    room: 'Buồng 301 - Giường 03',
    pod: 'POD 2',
    status: PatientStatus.yellow,
    age: 55,
    gender: 'Nam',
    surgeryDate: '10/05/2025',
    pathway: 'Hepatobiliary pathway',
    bmi: 25.1,
    surgeryType: 'Gan mật',
    nurseInCharge: 'ĐD. Lê Thị Mai',
    doctorInCharge: 'BS. Phạm Văn Hùng',
    alertCount: 1,
    assessmentDone: 1,
    assessmentTotal: 2,
    lastAssessmentTime: '12/05/2025 06:00',
    needsIntervention: false,
  ),
];
