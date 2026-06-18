import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/models/patient_summary.dart';

class NursePatientsPage extends StatefulWidget {
  const NursePatientsPage({super.key});

  @override
  State<NursePatientsPage> createState() => _NursePatientsPageState();
}

class _NursePatientsPageState extends State<NursePatientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter state — null = "Tất cả"
  String? _selectedPod;
  String? _selectedPathway;
  String? _selectedAiLevel;

  static const _patients = kMockPatients;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PatientSummary> get _filtered {
    return _patients.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.room.toLowerCase().contains(q);
      final matchPod = _selectedPod == null || p.pod == _selectedPod;
      final matchStatus =
          _selectedAiLevel == null || p.status.name == _selectedAiLevel;
      return matchSearch && matchPod && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // ── Top App Bar ──────────────────────────────────────────────
        _TopAppBar(
          onSearchTap: () => FocusScope.of(context).requestFocus(),
          onFilterTap: () => _showFilterSheet(context),
        ),

        // ── Body ─────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              // Search bar
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),

              // Filter chips row
              _FilterChipsRow(
                selectedPod: _selectedPod,
                selectedPathway: _selectedPathway,
                selectedAiLevel: _selectedAiLevel,
                onPodTap: () => _showPodPicker(context),
                onPathwayTap: () => _showPathwayPicker(context),
                onAiLevelTap: () => _showAiLevelPicker(context),
              ),
              const SizedBox(height: 10),

              // Count + sort row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng: ${filtered.length} người bệnh',
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

              // Patient cards
              ...filtered.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PatientCard(
                    data: p,
                    onTap: () => context.push(
                      AppRoutes.nursePatientDetailPath(p.code),
                      extra: p,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
      title: 'Chọn Pathway',
      options: const ['ERAS', 'Standard', 'Complex'],
      selected: _selectedPathway,
      onSelect: (v) => setState(() => _selectedPathway = v),
    );
  }

  void _showAiLevelPicker(BuildContext context) {
    _showSimplePicker(
      context,
      title: 'Chọn mức độ',
      options: const ['red', 'yellow', 'green'],
      optionLabels: const ['RED', 'YELLOW', 'GREEN'],
      selected: _selectedAiLevel,
      onSelect: (v) => setState(() => _selectedAiLevel = v),
    );
  }

  void _showSimplePicker(
    BuildContext context, {
    required String title,
    required List<String> options,
    List<String>? optionLabels,
    String? selected,
    required ValueChanged<String?> onSelect,
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
            // "Tất cả" option
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Top App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.onSearchTap, required this.onFilterTap});

  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () {},
              ),
              const Expanded(
                child: Text(
                  'Danh sách người bệnh',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips row
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Patient card — updated style matching new HTML
// ─────────────────────────────────────────────────────────────────────────────

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
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E7F4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selectedPod,
    required this.selectedAiLevel,
    required this.onApply,
    required this.onReset,
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
