import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/doctor/presentation/providers/doctor_patient_provider.dart';

class DoctorDashboardPage extends ConsumerWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final doctorState = ref.watch(doctorPatientsNotifierProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        _DoctorTopAppBar(user: user),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(doctorPatientsNotifierProvider.notifier).loadPatients(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DoctorDateRow(),
                  const SizedBox(height: 24),

                  // ── Tổng quan toàn viện ────────────────────────────────
                  const _SectionLabel(label: 'TỔNG QUAN TOÀN VIỆN'),
                  const SizedBox(height: 10),
                  _WardOverviewGrid(patients: doctorState.patients),
                  const SizedBox(height: 24),

                  // ── Bệnh nhân cần ưu tiên ──────────────────────────────
                  _SectionHeader(
                    label: 'BỆNH NHÂN CẦN THEO DÕI',
                    onViewAll: () => context.go(AppRoutes.doctorPatients),
                  ),
                  const SizedBox(height: 10),
                  _PriorityList(patients: doctorState.patients),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorTopAppBar extends StatelessWidget {
  const _DoctorTopAppBar({required this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Bác sĩ';

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: AppColors.primaryContainer,
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BS. $displayName',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'BÁC SĨ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFFB3C5FF),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'POMS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date row
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorDateRow extends StatelessWidget {
  const _DoctorDateRow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm',
      'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
    ];
    final weekday = weekdays[now.weekday - 1];
    final dateStr =
        '$weekday, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        dateStr,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF424656),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.onViewAll});
  final String label;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF424656),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            'Xem tất cả',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ward overview grid
// ─────────────────────────────────────────────────────────────────────────────

class _WardOverviewGrid extends StatelessWidget {
  const _WardOverviewGrid({required this.patients});
  final List<PatientSummary> patients;

  @override
  Widget build(BuildContext context) {
    final total = patients.length;
    final green = patients.where((p) => p.status == PatientStatus.green).length;
    final yellow = patients.where((p) => p.status == PatientStatus.yellow).length;
    final red = patients.where((p) => p.status == PatientStatus.red).length;

    String pct(int count) =>
        total == 0 ? '(0%)' : '(${(count / total * 100).toStringAsFixed(1)}%)';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TỔNG BN',
            value: '$total',
            valueColor: AppColors.primary,
            leftBorderColor: Colors.transparent,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatCard(
            label: 'GREEN',
            labelColor: const Color(0xFF2E7D32),
            value: '$green',
            sub: pct(green),
            leftBorderColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatCard(
            label: 'YELLOW',
            labelColor: const Color(0xFFF57F17),
            value: '$yellow',
            sub: pct(yellow),
            leftBorderColor: const Color(0xFFFFC107),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatCard(
            label: 'RED',
            labelColor: AppColors.error,
            value: '$red',
            sub: pct(red),
            leftBorderColor: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.leftBorderColor,
    this.labelColor = const Color(0xFF424656),
    this.valueColor = const Color(0xFF191B24),
    this.sub,
  });

  final String label;
  final Color labelColor;
  final String value;
  final Color valueColor;
  final Color leftBorderColor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (leftBorderColor != Colors.transparent)
              Container(width: 4, color: leftBorderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Color(0xFF424656),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Priority patient list (RED + YELLOW, up to 5)
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityList extends StatelessWidget {
  const _PriorityList({required this.patients});
  final List<PatientSummary> patients;

  @override
  Widget build(BuildContext context) {
    final sorted = [...patients]..sort((a, b) {
        const order = {
          PatientStatus.red: 0,
          PatientStatus.yellow: 1,
          PatientStatus.green: 2,
        };
        final cmp = order[a.status]!.compareTo(order[b.status]!);
        return cmp != 0 ? cmp : a.pod.compareTo(b.pod);
      });

    final display = sorted
        .where((p) =>
            p.status == PatientStatus.red || p.status == PatientStatus.yellow)
        .take(5)
        .toList();

    if (display.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E0)),
        ),
        child: const Center(
          child: Text(
            'Không có bệnh nhân cần theo dõi đặc biệt',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF727687),
            ),
          ),
        ),
      );
    }

    return Column(
      children: display
          .map(
            (patient) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PatientCard(
                patient: patient,
                onTap: () => context.push(
                  AppRoutes.doctorPatientDetailPath(patient.code),
                  extra: patient,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onTap});
  final PatientSummary patient;
  final VoidCallback onTap;

  Color get _statusColor => patient.status.badgeText;
  Color get _statusBg => patient.status.badgeBg;
  String get _statusLabel => patient.status.label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFECEDFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            patient.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191B24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.room} • ${patient.pod}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC2C6D8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
