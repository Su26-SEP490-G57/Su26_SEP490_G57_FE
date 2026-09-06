import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_state.dart';
import 'package:poms/features/nurse/presentation/widgets/patient_pagination.dart';

/// Danh sách toàn bộ người bệnh trong viện dành cho Bác sĩ (không giới hạn phòng).
class DoctorPatientsPage extends ConsumerStatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
  final _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 5;

  String _searchQuery = '';

  // Filter state — Mặc định chọn tất cả
  final Set<PatientStatus> _selectedStatuses = {
    PatientStatus.red,
    PatientStatus.yellow,
    PatientStatus.green,
  };

  // Swipe direction: +1 = forward (next), -1 = backward (prev)
  int _swipeDirection = 1;

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

  void _toggleStatus(PatientStatus status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        if (_selectedStatuses.length > 1) {
          _selectedStatuses.remove(status);
        }
      } else {
        _selectedStatuses.add(status);
      }

      _currentPage = 1;
    });
  }

  List<PatientSummary> _paginate(List<PatientSummary> patients, int page) {
    final start = (page - 1) * _pageSize;
    if (start >= patients.length) return [];
    final end = (start + _pageSize).clamp(0, patients.length);
    return patients.sublist(start, end);
  }

  void _goNext(int totalPages) {
    if (_currentPage >= totalPages) return;
    setState(() {
      _swipeDirection = 1;
      _currentPage++;
    });
  }

  void _goPrev() {
    if (_currentPage <= 1) return;
    setState(() {
      _swipeDirection = -1;
      _currentPage--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientNotifierProvider);

    if (patientState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (patientState.status == PatientStatusState.error) {
      return Scaffold(
        body: Center(
          child: Text(patientState.errorMessage ?? 'Có lỗi xảy ra'),
        ),
      );
    }

    final filteredPatients = _filtered(patientState.patients);
    final totalPages = max(1, (filteredPatients.length / _pageSize).ceil());
    final currentPage = min(_currentPage, totalPages);
    final pagedPatients = _paginate(filteredPatients, currentPage);

    final startIndex = filteredPatients.isEmpty
        ? 0
        : (currentPage - 1) * _pageSize + 1;

    final endIndex = min(currentPage * _pageSize, filteredPatients.length);

    return Column(
      children: [
        // ── Top App Bar ──────────────────────────────────────────────
        _DoctorPatientsTopAppBar(totalPatients: patientState.patients.length),

        // ── Body ─────────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            // Swipe right-to-left → next page
            // Swipe left-to-right → prev page
            onHorizontalDragEnd: (details) {
              const threshold = 80.0;
              final dx = details.primaryVelocity ?? 0;
              if (dx < -threshold) {
                _goNext(totalPages);
              } else if (dx > threshold) {
                _goPrev();
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                // ── Search bar ───────────────────────────────────────
                _SearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filter chips row
                _FilterChipsRow(
                  selectedStatuses: _selectedStatuses,
                  onStatusTap: _toggleStatus,
                ),
                const SizedBox(height: 10),

                // Count + sort row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng: ${filteredPatients.length} người bệnh',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF727687),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(
                            Icons.sort_rounded,
                            size: 14,
                            color: Color(0xFF727687),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ưu tiên: Đỏ → Vàng → Xanh',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF727687),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Animated patient list ─────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final isIncoming = child.key == ValueKey<int>(currentPage);
                    final position = isIncoming
                        ? Tween<Offset>(
                            begin: Offset(_swipeDirection.toDouble(), 0),
                            end: Offset.zero,
                          ).animate(animation)
                        : Tween<Offset>(
                            begin: Offset.zero,
                            end: Offset(-_swipeDirection.toDouble(), 0),
                          ).animate(ReverseAnimation(animation));
                    return SlideTransition(
                      position: position,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Column(
                    key: ValueKey<int>(currentPage),
                    children: [
                      if (pagedPatients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Không có bệnh nhân nào phù hợp',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        )
                      else
                        ...pagedPatients.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DoctorPatientCard(
                              data: p,
                              onTap: () => context.push(
                                AppRoutes.doctorPatientDetailPath(p.code),
                                extra: p,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Pagination bar ────────────────────────────────────
                PatientPagination(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  startIndex: startIndex,
                  endIndex: endIndex,
                  total: filteredPatients.length,
                  onPrevious: _goPrev,
                  onNext: () => _goNext(totalPages),
                ),

                const SizedBox(height: 8),
              ],
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

class _DoctorPatientsTopAppBar extends StatelessWidget {
  const _DoctorPatientsTopAppBar({required this.totalPatients});

  final int totalPatients;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh sách người bệnh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Toàn viện • $totalPatients bệnh nhân',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
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
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C6D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF191B24),
        ),
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm người bệnh, mã, phòng...',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF727687),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color(0xFF727687),
            size: 20,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedStatuses,
    required this.onStatusTap,
  });

  final Set<PatientStatus> selectedStatuses;
  final ValueChanged<PatientStatus> onStatusTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusFilterChip(
            label: 'Đỏ',
            status: PatientStatus.red,
            selected: selectedStatuses.contains(PatientStatus.red),
            onTap: () => onStatusTap(PatientStatus.red),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusFilterChip(
            label: 'Vàng',
            status: PatientStatus.yellow,
            selected: selectedStatuses.contains(PatientStatus.yellow),
            onTap: () => onStatusTap(PatientStatus.yellow),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusFilterChip(
            label: 'Xanh',
            status: PatientStatus.green,
            selected: selectedStatuses.contains(PatientStatus.green),
            onTap: () => onStatusTap(PatientStatus.green),
          ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PatientStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PatientStatus.red => const Color(0xFFBA1A1A),
      PatientStatus.yellow => const Color(0xFFA33200),
      PatientStatus.green => const Color(0xFF006A61),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : const Color(0xFFC2C6D8)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : const Color(0xFF727687),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient card — matches Nurse style
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorPatientCard extends StatelessWidget {
  const _DoctorPatientCard({required this.data, required this.onTap});

  final PatientSummary data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC2C6D8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE6E7F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_circle_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),

            // Info — code + name + room
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.code,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.01 * 14,
                      color: Color(0xFF727687),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191B24),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.room,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF424656),
                    ),
                  ),
                ],
              ),
            ),

            // Right — POD + chevron trên, status pill dưới
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      data.pod,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF424656),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF424656),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _StatusPill(status: data.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final PatientStatus status;

  Color get _bg => switch (status) {
    PatientStatus.red => const Color(0x1ABA1A1A),
    PatientStatus.yellow => const Color(0x1ACC4204),
    PatientStatus.green => const Color(0x1A006A61),
  };

  Color get _border => switch (status) {
    PatientStatus.red => const Color(0x33BA1A1A),
    PatientStatus.yellow => const Color(0x33CC4204),
    PatientStatus.green => const Color(0x33006A61),
  };

  Color get _text => switch (status) {
    PatientStatus.red => const Color(0xFFBA1A1A),
    PatientStatus.yellow => const Color(0xFFA33200),
    PatientStatus.green => const Color(0xFF006A61),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: _text,
        ),
      ),
    );
  }
}
