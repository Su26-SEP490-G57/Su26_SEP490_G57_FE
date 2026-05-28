import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

/// Nurse Dashboard — không dùng Scaffold riêng vì NurseShell đã cung cấp.
class NurseDashboardPage extends ConsumerWidget {
  const NurseDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final displayName = user?.displayName ?? 'Nurse';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFFAF8FF),
          elevation: 1,
          shadowColor: Colors.black12,
          pinned: true,
          titleSpacing: 0,
          title: _AppBarTitle(displayName: displayName),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Chào buổi sáng, $displayName',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191B24),
                ),
              ),
              const SizedBox(height: 16),
              const _StatsGrid(),
              const SizedBox(height: 20),
              const _SectionHeader(
                icon: Icons.emergency,
                iconColor: Color(0xFFCC4204),
                title: 'Ưu tiên xử lý',
              ),
              const SizedBox(height: 8),
              const _PriorityPatientCard(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Theo dõi phục hồi ERAS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191B24),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0050CB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _ErasGrid(),
              const SizedBox(height: 20),
              const _SectionHeader(
                icon: Icons.assignment_late,
                iconColor: Color(0xFF0050CB),
                title: 'Nhiệm vụ cần làm',
              ),
              const SizedBox(height: 8),
              const _PendingTasksCard(),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar title
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E5E0)),
              color: const Color(0xFFDAE1FF),
            ),
            child: const Icon(Icons.person, color: Color(0xFF0050CB), size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POMS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0050CB),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Khoa Ngoại Tiêu Hóa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Ca sáng',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF191B24),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats bento grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: const [
        _StatCard(
          label: 'Bệnh nhân phụ trách',
          value: '08',
          icon: Icons.group_outlined,
          iconColor: Color(0xFF727687),
          bgColor: Color(0xFFFFFFFF),
          valueColor: Color(0xFF191B24),
        ),
        _StatCard(
          label: 'Cảnh báo mới',
          value: '03',
          icon: Icons.warning,
          iconColor: Color(0xFFBA1A1A),
          bgColor: Color(0xFFFFDAD6),
          valueColor: Color(0xFF93000A),
        ),
        _StatCard(
          label: 'Ca cần theo dõi',
          value: '02',
          icon: Icons.monitor_heart_outlined,
          iconColor: Color(0xFF006A61),
          bgColor: Color(0xFFFFFFFF),
          valueColor: Color(0xFF191B24),
        ),
        _StatCard(
          label: 'Nguy cơ cao',
          value: '01',
          icon: Icons.flag_outlined,
          iconColor: Color(0xFFCC4204),
          bgColor: Color(0xFFFFF6F4),
          valueColor: Color(0xFFCC4204),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: valueColor.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Priority patient card
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityPatientCard extends StatelessWidget {
  const _PriorityPatientCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: const Color(0xFFBA1A1A)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Badge(
                                  label: 'NGUY CƠ CAO',
                                  bg: const Color(0x1ABA1A1A),
                                  textColor: const Color(0xFFBA1A1A),
                                ),
                                const SizedBox(width: 8),
                                _Badge(
                                  label: 'POD 2',
                                  bg: const Color(0xFFE1E2EE),
                                  textColor: const Color(0xFF424656),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Nguyễn Văn A',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF191B24),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(
                                  Icons.meeting_room_outlined,
                                  size: 14,
                                  color: Color(0xFF424656),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'P.402 G.01',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF424656),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'CẬP NHẬT GẦN NHẤT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFF727687),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '10 phút trước',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF191B24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TRIỆU CHỨNG GHI NHẬN',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF727687),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _SymptomChip(
                          icon: Icons.sick_outlined,
                          label: 'Nôn liên tục (3 lần/giờ)',
                          color: Color(0xFFBA1A1A),
                          bg: Color(0x1ABA1A1A),
                        ),
                        _SymptomChip(
                          icon: Icons.restaurant_menu_outlined,
                          label: 'Chưa dung nạp thức ăn',
                          color: Color(0xFF424656),
                          bg: Color(0xFFE1E2EE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBA1A1A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text(
                                'Báo bác sĩ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0050CB),
                                side: const BorderSide(
                                  color: Color(0xFF0050CB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.update, size: 18),
                              label: const Text(
                                'Cập nhật',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
// ERAS grid
// ─────────────────────────────────────────────────────────────────────────────

class _ErasGrid extends StatelessWidget {
  const _ErasGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ErasCard(
          icon: Icons.soup_kitchen_outlined,
          iconBg: Color(0xFFFFDAD6),
          iconColor: Color(0xFF93000A),
          title: 'Dung nạp',
          value: '2/5 Kém',
          valueColor: Color(0xFFBA1A1A),
          progress: 0.4,
          progressColor: Color(0xFFBA1A1A),
        ),
        SizedBox(height: 8),
        _ErasCard(
          icon: Icons.directions_walk,
          iconBg: Color(0xFFE6F4EA),
          iconColor: Color(0xFF006A61),
          title: 'Vận động',
          value: '4/5 Đạt',
          valueColor: Color(0xFF006A61),
          progress: 0.8,
          progressColor: Color(0xFF006A61),
        ),
      ],
    );
  }
}

class _ErasCard extends StatelessWidget {
  const _ErasCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.progress,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final Color valueColor;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191B24),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE1E2EE),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
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
// Pending tasks card
// ─────────────────────────────────────────────────────────────────────────────

class _PendingTasksCard extends StatelessWidget {
  const _PendingTasksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_late,
                color: Color(0xFF0050CB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Nhiệm vụ cần làm',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191B24),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0050CB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFC2C6D8)),
          const _TaskItem(
            title: 'Chưa đánh giá dung nạp',
            subtitle: 'P.405 - Trương Thị B',
          ),
          const SizedBox(height: 10),
          const _TaskItem(
            title: 'Chưa cập nhật vận động',
            subtitle: 'P.301 - Lê Văn C',
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                'Xem toàn bộ danh sách',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0050CB),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC2C6D8).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_unchecked,
            color: Color(0xFF727687),
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF191B24),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });
  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF191B24),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.textColor,
  });
  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  const _SymptomChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF191B24),
            ),
          ),
        ],
      ),
    );
  }
}
