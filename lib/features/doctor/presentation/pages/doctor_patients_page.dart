import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/doctor/presentation/providers/doctor_patient_provider.dart';

/// Danh sách toàn bộ bệnh nhân dành cho bác sĩ — không giới hạn phòng.
class DoctorPatientsPage extends ConsumerStatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<PatientStatus> _selectedStatuses = {
    PatientStatus.red,
    PatientStatus.yellow,
    PatientStatus.green,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PatientSummary> _filtered(List<PatientSummary> patients) {
    return patients.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.room.toLowerCase().contains(q);
      final matchStatus = _selectedStatuses.contains(p.status);
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorPatientsNotifierProvider);
    final filtered = _filtered(doctorState.patients);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tất cả bệnh nhân',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () =>
                ref.read(doctorPatientsNotifierProvider.notifier).loadPatients(
                      search: _searchQuery.isNotEmpty ? _searchQuery : null,
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, mã, phòng...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF9CA3AF), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF9CA3AF), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),

          // ── Status filter chips ─────────────────────────────────────
          _StatusFilterRow(
            selectedStatuses: _selectedStatuses,
            onToggle: (status) {
              setState(() {
                if (_selectedStatuses.contains(status)) {
                  if (_selectedStatuses.length > 1) {
                    _selectedStatuses.remove(status);
                  }
                } else {
                  _selectedStatuses.add(status);
                }
              });
            },
          ),

          // ── Patient list ────────────────────────────────────────────
          Expanded(
            child: doctorState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : doctorState.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Lỗi: ${doctorState.errorMessage}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Inter', color: Colors.red),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(doctorPatientsNotifierProvider
                                        .notifier)
                                    .loadPatients(),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                child: const Text('Thử lại',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy bệnh nhân',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: Color(0xFF727687),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => ref
                                .read(doctorPatientsNotifierProvider.notifier)
                                .loadPatients(),
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                  16, 8, 16, bottomPad + 20),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final patient = filtered[index];
                                return _DoctorPatientCard(
                                  patient: patient,
                                  onTap: () => context.push(
                                    AppRoutes.doctorPatientDetailPath(
                                        patient.code),
                                    extra: patient,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status filter chips row
// ─────────────────────────────────────────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.selectedStatuses,
    required this.onToggle,
  });

  final Set<PatientStatus> selectedStatuses;
  final void Function(PatientStatus) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: PatientStatus.values.map((status) {
          final selected = selectedStatuses.contains(status);
          final color = status.badgeText;
          final bg = status.badgeBg;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onToggle(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? bg : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? color : const Color(0xFFE5E7EB),
                    width: selected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : const Color(0xFF727687),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient card
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorPatientCard extends StatelessWidget {
  const _DoctorPatientCard({
    required this.patient,
    required this.onTap,
  });

  final PatientSummary patient;
  final VoidCallback onTap;

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
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22),
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
                            color: patient.status.badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            patient.status.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: patient.status.badgeText,
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
                    if (patient.surgeryType != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        patient.surgeryType!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF727687),
                        ),
                      ),
                    ],
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
