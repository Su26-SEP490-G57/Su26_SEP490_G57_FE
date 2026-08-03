import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/patient/domain/models/health_education_model.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';

class PatientHealthEducationPage extends ConsumerStatefulWidget {
  const PatientHealthEducationPage({super.key});

  @override
  ConsumerState<PatientHealthEducationPage> createState() =>
      _PatientHealthEducationPageState();
}

class _PatientHealthEducationPageState
    extends ConsumerState<PatientHealthEducationPage> {
  int _selectedPod = 0;
  bool _isInitialPodSet = false;

  @override
  Widget build(BuildContext context) {
    final currentPodAsync = ref.watch(currentPodProvider);

    // Auto-set selected POD to patient's active POD once data loads
    currentPodAsync.whenData((podData) {
      if (!_isInitialPodSet && podData?.currentPod != null) {
        final activePod = podData!.currentPod!.clamp(0, 7);
        setState(() {
          _selectedPod = activePod;
          _isInitialPodSet = true;
        });
      }
    });

    final currentEduData = podHealthEducationData.firstWhere(
      (e) => e.podNumber == _selectedPod,
      orElse: () => podHealthEducationData.first,
    );

    final patientPodNum = currentPodAsync.valueOrNull?.currentPod;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onSurface,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.patientDashboard);
            }
          },
        ),
        title: const Text(
          'Giáo dục sức khỏe',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            tooltip: 'Thông báo hệ thống',
            onPressed: () => context.push(AppRoutes.patientNotifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Phase Banner Header & POD Selector Bar
            _PodSelectorHeader(
              selectedPod: _selectedPod,
              patientPodNum: patientPodNum,
              currentEduData: currentEduData,
              onPodSelected: (pod) => setState(() => _selectedPod = pod),
            ),
            const SizedBox(height: 16),

            // Scrollable 4 Cards Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).padding.bottom + 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Mục tiêu hôm nay
                    _GoalsCard(goals: currentEduData.goals),
                    const SizedBox(height: 16),

                    // Card 2: Bạn cần thực hiện
                    _ActionsCard(actions: currentEduData.actions),
                    const SizedBox(height: 16),

                    // Card 3: Cảnh báo / Báo y tế ngay
                    _WarningsCard(
                      header: currentEduData.warningHeader,
                      warnings: currentEduData.warnings,
                    ),
                    const SizedBox(height: 16),

                    // Card 4: Lưu ý
                    _NotesCard(note: currentEduData.note),
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
// POD Selector Header & Phase Banner
// ─────────────────────────────────────────────────────────────────────────────

class _PodSelectorHeader extends StatelessWidget {
  const _PodSelectorHeader({
    required this.selectedPod,
    required this.patientPodNum,
    required this.currentEduData,
    required this.onPodSelected,
  });

  final int selectedPod;
  final int? patientPodNum;
  final PodHealthEducation currentEduData;
  final ValueChanged<int> onPodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Phase Banner Tag & Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selectedPod <= 4
                    ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                    : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: selectedPod <= 4
                      ? const Color(0x200284C7)
                      : const Color(0x200D9488),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  selectedPod <= 4
                      ? Icons.health_and_safety_rounded
                      : Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentEduData.phaseName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE0F2FE),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'POD $selectedPod — ${currentEduData.podSubtitle}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal POD Selector Bar
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == selectedPod;
              final isCurrentPatientPod = index == patientPodNum;

              return ChoiceChip(
                showCheckmark: false,
                selected: isSelected,
                onSelected: (_) => onPodSelected(index),
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : isCurrentPatientPod
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0),
                  width: isSelected || isCurrentPatientPod ? 1.8 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'POD $index',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    if (isCurrentPatientPod) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFFDE047)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 1: Mục tiêu hôm nay
// ─────────────────────────────────────────────────────────────────────────────

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});

  final List<String> goals;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mục tiêu hôm nay',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0369A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.fiber_manual_record,
                      size: 7,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 2: Bạn cần thực hiện
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bạn cần thực hiện',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF064E3B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 3: Cảnh báo y tế (Header verbatim)
// ─────────────────────────────────────────────────────────────────────────────

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.header, required this.warnings});

  final String header;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECDD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE11D48),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  header,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE123C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.fiber_manual_record,
                      size: 7,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF881337),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 4: Lưu ý
// ─────────────────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF6D28D9),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lưu ý',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B21B6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4C1D95),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
