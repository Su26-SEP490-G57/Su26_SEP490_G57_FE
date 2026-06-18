import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/patient_summary.dart';

class NursePatientDetailPage extends StatefulWidget {
  const NursePatientDetailPage({
    super.key,
    required this.patientId,
    this.patient,
  });

  final String patientId;
  final PatientSummary? patient;

  @override
  State<NursePatientDetailPage> createState() => _NursePatientDetailPageState();
}

class _NursePatientDetailPageState extends State<NursePatientDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PatientSummary _patient;

  static const _tabs = [
    'Tổng quan',
    'Assessment',
    'Timeline',
    'Alert',
    'Ghi chú',
  ];

  @override
  void initState() {
    super.initState();
    _patient =
        widget.patient ??
        kMockPatients.firstWhere(
          (p) => p.code == widget.patientId,
          orElse: () => kMockPatients.first,
        );
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Pinned AppBar — không expandedHeight, không FlexibleSpace ──
          SliverAppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            pinned: true,
            floating: false,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Chi tiết người bệnh',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
          ),

          // ── Hero section — Container riêng, bo 2 góc dưới ──────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _PatientHero(patient: _patient),
            ),
          ),

          // ── TabBar sticky ────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF424656),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                dividerColor: const Color(0xFFC2C6D8),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(patient: _patient),
            const _PlaceholderTab(label: 'Assessment'),
            const _PlaceholderTab(label: 'Timeline'),
            const _PlaceholderTab(label: 'Alert'),
            const _PlaceholderTab(label: 'Ghi chú'),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomActionBar(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBar sticky delegate
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => tabBar != old.tabBar;
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient hero
// ─────────────────────────────────────────────────────────────────────────────

class _PatientHero extends StatelessWidget {
  const _PatientHero({required this.patient});
  final PatientSummary patient;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDAE1FF), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: patient.status.dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${patient.code} - ${patient.name}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: patient.status.solidBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      patient.status.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Opacity(
                opacity: 0.9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${patient.pod}${patient.surgeryType != null ? ' - ${patient.surgeryType}' : ''}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          patient.room,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.patient});
  final PatientSummary patient;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        _InfoGrid(patient: patient),
        const SizedBox(height: 16),
        if (patient.needsIntervention) ...[
          _AlertBanner(patient: patient),
          const SizedBox(height: 16),
        ],
        _SummaryGrid(patient: patient),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info grid
// ─────────────────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.patient});
  final PatientSummary patient;

  String _initials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '??';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Thông tin chung',
          child: Column(
            children: [
              if (patient.age != null)
                _InfoRow(label: 'Tuổi', value: '${patient.age}'),
              if (patient.gender != null)
                _InfoRow(label: 'Giới tính', value: patient.gender!),
              if (patient.surgeryDate != null)
                _InfoRow(label: 'Ngày phẫu thuật', value: patient.surgeryDate!),
              if (patient.pathway != null)
                _InfoRow(label: 'Pathway', value: patient.pathway!),
              if (patient.bmi != null)
                _InfoRow(
                  label: 'BMI',
                  value: patient.bmi!.toStringAsFixed(1),
                  isLast: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Nhân sự phụ trách',
          child: Column(
            children: [
              if (patient.nurseInCharge != null)
                _PersonnelItem(
                  initials: _initials(patient.nurseInCharge),
                  name: patient.nurseInCharge!,
                  role: 'Điều dưỡng chính',
                  bgColor: const Color(0xFFDAE1FF),
                  textColor: AppColors.primary,
                ),
              if (patient.nurseInCharge != null &&
                  patient.doctorInCharge != null)
                const SizedBox(height: 8),
              if (patient.doctorInCharge != null)
                _PersonnelItem(
                  initials: _initials(patient.doctorInCharge),
                  name: patient.doctorInCharge!,
                  role: 'Bác sĩ phụ trách',
                  bgColor: const Color(0xFFFFDBD0),
                  textColor: const Color(0xFFA33200),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF424656),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF424656),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191B24),
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFECEDFA)),
      ],
    );
  }
}

class _PersonnelItem extends StatelessWidget {
  const _PersonnelItem({
    required this.initials,
    required this.name,
    required this.role,
    required this.bgColor,
    required this.textColor,
  });
  final String initials;
  final String name;
  final String role;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191B24),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF424656),
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

// ─────────────────────────────────────────────────────────────────────────────
// Alert banner
// ─────────────────────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.patient});
  final PatientSummary patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái hiện tại: Cần can thiệp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF93000A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thời gian đánh giá gần nhất: ${patient.lastAssessmentTime ?? 'Chưa có'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF93000A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.error,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary grid
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.patient});
  final PatientSummary patient;

  @override
  Widget build(BuildContext context) {
    final assessmentStr = patient.assessmentTotal > 0
        ? '${patient.assessmentDone}/${patient.assessmentTotal}'
        : '-';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        _SummaryCard(
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFF006A61),
          label: 'ĐÁNH GIÁ',
          value: assessmentStr,
          valueColor: const Color(0xFF191B24),
          bgColor: Colors.white,
        ),
        _SummaryCard(
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.error,
          label: 'ALERT',
          value: '${patient.alertCount}',
          valueColor: patient.alertCount > 0
              ? AppColors.error
              : const Color(0xFF191B24),
          bgColor: Colors.white,
        ),
        _SummaryCard(
          icon: Icons.smart_toy_outlined,
          iconColor: patient.status.badgeText,
          label: 'MỨC ĐỘ',
          value: patient.status.label,
          valueColor: patient.status.badgeText,
          bgColor: patient.status == PatientStatus.red
              ? const Color(0xFFFFDAD6)
              : patient.status == PatientStatus.yellow
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFE8F5E9),
        ),
        _SummaryCard(
          icon: Icons.calendar_view_day_outlined,
          iconColor: AppColors.primary,
          label: 'POD',
          value: patient.podNumber,
          valueColor: const Color(0xFF191B24),
          bgColor: Colors.white,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bgColor,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF424656),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        border: Border(top: BorderSide(color: Color(0xFFC2C6D8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call_outlined, size: 20),
              label: const Text('Gọi điện'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_outlined, size: 20),
              label: const Text('Chat với BN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder tab
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}
