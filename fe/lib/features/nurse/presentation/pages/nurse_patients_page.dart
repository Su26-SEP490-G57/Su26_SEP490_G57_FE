import 'package:flutter/material.dart';

/// Nurse Patients Page — không dùng Scaffold riêng vì NurseShell đã cung cấp.
class NursePatientsPage extends StatefulWidget {
  const NursePatientsPage({super.key});

  @override
  State<NursePatientsPage> createState() => _NursePatientsPageState();
}

class _NursePatientsPageState extends State<NursePatientsPage> {
  int _selectedFilter = 0;
  final _searchController = TextEditingController();

  static const _filters = ['Tất cả', 'Cần theo dõi', 'Ổn định', 'Nguy cơ cao'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── AppBar ──────────────────────────────────────────────────
        Container(
          color: const Color(0xFFFAF8FF),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E5E0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      color: const Color(0xFFDAE1FF),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF0050CB),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'POMS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0050CB),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'ICU • Ca sáng',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424656),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Search + filters ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF191B24),
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm tên bệnh nhân hoặc số giường...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Color(0xFF727687),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF727687),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF0050CB),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final isSelected = _selectedFilter == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0050CB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0050CB)
                                : const Color(0xFFC2C6D8),
                          ),
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF424656),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Patient list ─────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _PatientCard(
                name: 'Lê Văn C',
                room: 'P.401 - G.01',
                surgery: 'Nội soi đại tràng',
                pod: 'POD 3',
                status: _PatientStatus.critical,
                lastSymptom: 'Khó thở',
                lastSymptomIcon: Icons.air_outlined,
                lastUpdate: 'Vừa xong',
                lastUpdateColor: const Color(0xFFBA1A1A),
              ),
              const SizedBox(height: 12),
              _PatientCard(
                name: 'Trần Thị B',
                room: 'P.405 - G.02',
                surgery: 'Mổ sỏi túi mật',
                pod: 'POD 1',
                status: _PatientStatus.warning,
                lastSymptom: 'Buồn nôn nhẹ',
                lastSymptomIcon: Icons.sick_outlined,
                lastUpdate: '5 phút trước',
                lastUpdateColor: const Color(0xFF727687),
              ),
              const SizedBox(height: 12),
              _PatientCard(
                name: 'Nguyễn Văn A',
                room: 'P.402 - G.01',
                surgery: 'Cắt dạ dày',
                pod: 'POD 2',
                status: _PatientStatus.stable,
                lastSymptom: 'Không có triệu chứng',
                lastSymptomIcon: Icons.sentiment_satisfied_outlined,
                lastUpdate: '15 phút trước',
                lastUpdateColor: const Color(0xFF727687),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient status
// ─────────────────────────────────────────────────────────────────────────────

enum _PatientStatus { critical, warning, stable }

extension _PatientStatusX on _PatientStatus {
  String get label => switch (this) {
    _PatientStatus.critical => 'NGUY CƠ CAO',
    _PatientStatus.warning => 'CẦN THEO DÕI',
    _PatientStatus.stable => 'ỔN ĐỊNH',
  };

  Color get bg => switch (this) {
    _PatientStatus.critical => const Color(0xFFFFDAD6),
    _PatientStatus.warning => const Color(0xFFFFF8E1),
    _PatientStatus.stable => const Color(0xFFE8F5E9),
  };

  Color get textColor => switch (this) {
    _PatientStatus.critical => const Color(0xFF93000A),
    _PatientStatus.warning => const Color(0xFFF57F17),
    _PatientStatus.stable => const Color(0xFF2E7D32),
  };

  Color get borderColor => switch (this) {
    _PatientStatus.critical => const Color(0xFFBA1A1A).withValues(alpha: 0.2),
    _PatientStatus.warning => const Color(0xFFF57F17).withValues(alpha: 0.2),
    _PatientStatus.stable => const Color(0xFF2E7D32).withValues(alpha: 0.2),
  };

  Color get leftBarColor => switch (this) {
    _PatientStatus.critical => const Color(0xFFBA1A1A),
    _PatientStatus.warning => const Color(0xFFF57F17),
    _PatientStatus.stable => Colors.transparent,
  };

  IconData get icon => switch (this) {
    _PatientStatus.critical => Icons.warning_outlined,
    _PatientStatus.warning => Icons.visibility_outlined,
    _PatientStatus.stable => Icons.check_circle_outlined,
  };

  Color get symptomIconColor => switch (this) {
    _PatientStatus.critical => const Color(0xFFBA1A1A),
    _PatientStatus.warning => const Color(0xFFF57F17),
    _PatientStatus.stable => const Color(0xFF2E7D32),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient card
// ─────────────────────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.name,
    required this.room,
    required this.surgery,
    required this.pod,
    required this.status,
    required this.lastSymptom,
    required this.lastSymptomIcon,
    required this.lastUpdate,
    required this.lastUpdateColor,
  });

  final String name;
  final String room;
  final String surgery;
  final String pod;
  final _PatientStatus status;
  final String lastSymptom;
  final IconData lastSymptomIcon;
  final String lastUpdate;
  final Color lastUpdateColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to patient detail
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == _PatientStatus.critical
                ? const Color(0xFFFFDAD6)
                : const Color(0xFFE5E5E0),
          ),
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
              if (status.leftBarColor != Colors.transparent)
                Container(width: 4, color: status.leftBarColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    status.leftBarColor != Colors.transparent ? 12 : 16,
                    16,
                    16,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF191B24),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                room,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF424656),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: status.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status.icon,
                                  size: 12,
                                  color: status.textColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status.label,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: status.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Surgery + POD
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PHẪU THUẬT',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF727687),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  surgery,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF191B24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NGÀY HẬU PHẪU',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF727687),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pod,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF191B24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Latest record
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFC2C6D8,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'GHI NHẬN MỚI NHẤT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFF727687),
                              ),
                            ),
                            Text(
                              lastUpdate,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: lastUpdateColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            lastSymptomIcon,
                            size: 16,
                            color: status.symptomIconColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lastSymptom,
                            style: const TextStyle(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
