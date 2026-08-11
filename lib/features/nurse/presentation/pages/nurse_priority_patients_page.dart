import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/assigned_rooms_provider.dart';
import 'package:poms/features/nurse/presentation/providers/priority_patients_provider.dart';

class NursePriorityPatientsPage extends ConsumerStatefulWidget {
  const NursePriorityPatientsPage({super.key});

  @override
  ConsumerState<NursePriorityPatientsPage> createState() =>
      _NursePriorityPatientsPageState();
}

class _NursePriorityPatientsPageState
    extends ConsumerState<NursePriorityPatientsPage> {
  final _searchController = TextEditingController();

  String? _selectedPod;
  String? _selectedPathway;
  String? _selectedAiLevel;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        selectedPod: _selectedPod,
        selectedAiLevel: _selectedAiLevel,
        onApply: (pod, aiLevel) {
          setState(() {
            _selectedPod = pod;
            _selectedAiLevel = aiLevel;
          });
          Navigator.of(context).pop();
        },
        onReset: () {
          setState(() {
            _selectedPod = null;
            _selectedAiLevel = null;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showPodPicker(BuildContext context) {
    _showSimplePicker(
      context,
      title: 'Chọn POD',
      options: const ['POD 1', 'POD 2', 'POD 3', 'POD 4', 'POD 5'],
      selected: _selectedPod,
      onSelect: (v) => setState(() => _selectedPod = v),
    );
  }

  void _showPathwayPicker(BuildContext context) {
    _showSimplePicker(
      context,
      title: 'Chọn phác đồ',
      options: const ['ERAS', 'Tiêu chuẩn', 'Phức tạp'],
      selected: _selectedPathway,
      onSelect: (v) => setState(() => _selectedPathway = v),
    );
  }

  void _showAiLevelPicker(BuildContext context) {
    _showSimplePicker(
      context,
      title: 'Chọn mức độ',
      options: const ['red', 'yellow'],
      optionLabels: const ['Đỏ (Nguy cơ)', 'Vàng (Cần theo dõi)'],
      selected: _selectedAiLevel,
      onSelect: (v) => setState(() => _selectedAiLevel = v),
    );
  }

  void _showSimplePicker(
    BuildContext context, {
    required String title,
    required List<String> options,
    required ValueChanged<String?> onSelect,
    List<String>? optionLabels,
    String? selected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF8FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC2C6D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191B24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PickerItem(
              label: 'Tất cả',
              isSelected: selected == null,
              onTap: () {
                onSelect(null);
                Navigator.of(context).pop();
              },
            ),
            ...options.asMap().entries.map((e) {
              final label = optionLabels?[e.key] ?? e.value;
              return _PickerItem(
                label: label,
                isSelected: selected == e.value,
                onTap: () {
                  onSelect(e.value);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUnassignedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 56,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa được phân công phụ trách phòng bệnh nào.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng liên hệ Điều dưỡng trưởng để được phân công phòng bệnh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(priorityPatientsProvider);
    final assignedRoomsAsync = ref.watch(assignedRoomsProvider);

    final assignedRooms = assignedRoomsAsync.value ?? [];
    final isUnassigned = assignedRooms.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: Column(
        children: [
          _TopAppBar(
            assignedRooms: assignedRooms,
            onSearchTap: () => FocusScope.of(context).requestFocus(),
            onFilterTap: () => _showFilterSheet(context),
          ),
          Expanded(
            child: isUnassigned
                ? _buildUnassignedState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      _SearchBar(
                        controller: _searchController,
                        onChanged: (v) =>
                            ref
                                    .read(
                                      priorityPatientsSearchQueryProvider
                                          .notifier,
                                    )
                                    .state =
                                v,
                      ),
                      const SizedBox(height: 12),
                      _FilterChipsRow(
                        selectedPod: _selectedPod,
                        selectedPathway: _selectedPathway,
                        selectedAiLevel: _selectedAiLevel,
                        onPodTap: () => _showPodPicker(context),
                        onPathwayTap: () => _showPathwayPicker(context),
                        onAiLevelTap: () => _showAiLevelPicker(context),
                      ),
                      const SizedBox(height: 10),
                      patientsAsync.when(
                        data: (patients) {
                          // Local filtering for POD and Level since API might not handle all
                          final filtered = patients.where((p) {
                            final matchPod =
                                _selectedPod == null || p.pod == _selectedPod;
                            final matchLevel =
                                _selectedAiLevel == null ||
                                p.status.name == _selectedAiLevel;
                            return matchPod && matchLevel;
                          }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tổng: ${filtered.length} người bệnh ưu tiên',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF727687),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.sort_rounded,
                                            size: 14,
                                            color: Color(0xFF727687),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Sắp xếp',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.6,
                                              color: Color(0xFF727687),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (filtered.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'Không có bệnh nhân ưu tiên nào.',
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _PatientCard(
                                      data: p,
                                      onTap: () {
                                        debugPrint('push code = ${p.code}');
                                        debugPrint('push name = ${p.name}');

                                        context.push(
                                          AppRoutes.nursePatientDetailPath(
                                            p.code,
                                          ),
                                          extra: p,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Lỗi: $err')),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components (Duplicated from NursePatientsPage to avoid modifying it)
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    required this.onSearchTap,
    required this.onFilterTap,
    required this.assignedRooms,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;
  final List<String> assignedRooms;

  @override
  Widget build(BuildContext context) {
    final roomsText = assignedRooms.isEmpty
        ? 'Chưa phân phòng'
        : 'Phòng: ${assignedRooms.join(", ")}';

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bệnh nhân ưu tiên',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      roomsText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: onSearchTap,
              ),
              IconButton(
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                ),
                onPressed: onFilterTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
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
          hintText: 'Tìm kiếm người bệnh...',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF727687),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color(0xFF727687),
            size: 22,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedPod,
    required this.selectedPathway,
    required this.selectedAiLevel,
    required this.onPodTap,
    required this.onPathwayTap,
    required this.onAiLevelTap,
  });

  final String? selectedPod;
  final String? selectedPathway;
  final String? selectedAiLevel;
  final VoidCallback onPodTap;
  final VoidCallback onPathwayTap;
  final VoidCallback onAiLevelTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: selectedPod ?? 'Tất cả POD',
            isActive: selectedPod != null,
            onTap: onPodTap,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: selectedPathway ?? 'Tất cả pathway',
            isActive: selectedPathway != null,
            onTap: onPathwayTap,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: selectedAiLevel != null
                ? selectedAiLevel!.toUpperCase()
                : 'Tất cả mức độ',
            isActive: selectedAiLevel != null,
            onTap: onAiLevelTap,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFE6E7F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFC2C6D8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : const Color(0xFF424656),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: isActive ? AppColors.primary : const Color(0xFF424656),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.data, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.badgeBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.badgeText.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: status.badgeText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.onApply,
    required this.onReset,
    this.selectedPod,
    this.selectedAiLevel,
  });

  final String? selectedPod;
  final String? selectedAiLevel;
  final void Function(String? pod, String? aiLevel) onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC2C6D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191B24),
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onApply(selectedPod, selectedAiLevel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF191B24),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
