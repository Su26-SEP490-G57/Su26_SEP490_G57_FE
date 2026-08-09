import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/nurse/domain/models/assessment_detail.dart';
import 'package:poms/features/nurse/presentation/providers/assessment_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/patient_summary.dart';

class NursePatientDetailPage extends ConsumerStatefulWidget {
  const NursePatientDetailPage({
    required this.patientId,
    super.key,
    this.patient,
  });

  final String patientId;
  final PatientSummary? patient;

  @override
  ConsumerState<NursePatientDetailPage> createState() =>
      _NursePatientDetailPageState();
}

class _NursePatientDetailPageState extends ConsumerState<NursePatientDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Tổng quan', 'Đánh giá triệu chứng', 'Ghi chú'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livePatient = ref.watch(patientByIdProvider(widget.patientId));
    final assessmentState = ref.watch(
      assessmentNotifierProvider(widget.patientId),
    );
    final patient =
        livePatient ??
        widget.patient ??
        kMockPatients.firstWhere(
          (p) => p.code == widget.patientId,
          orElse: () => kMockPatients.first,
        );

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
              child: _PatientHero(patient: patient),
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
            _OverviewTab(
              patient: patient,
              assessmentState: assessmentState,
              onAssessmentTap: () {
                _tabController.animateTo(1);
              },
            ),
            _AssessmentTab(caseId: widget.patientId),
            _NotesTab(notes: _mockNotes),
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

  String _displayPod(String pod) {
    return pod.replaceFirst(
      RegExp(r'^POD\s*', caseSensitive: false),
      'Hậu phẫu ',
    );
  }

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
                          '${_displayPod(patient.pod)}${patient.surgeryType != null ? ' - ${patient.surgeryType}' : ''}',
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
  const _OverviewTab({
    required this.patient,
    required this.assessmentState,
    required this.onAssessmentTap,
  });

  final PatientSummary? patient;
  final AssessmentState assessmentState;
  final VoidCallback onAssessmentTap;

  @override
  Widget build(BuildContext context) {
    if (patient == null) {
      return const Center(child: Text('Không có thông tin bệnh nhân'));
    }
    final p = patient!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        _InfoGrid(patient: p),
        const SizedBox(height: 16),

        if (p.needsIntervention) ...[
          _AlertBanner(patient: p),
          const SizedBox(height: 16),
        ],
        const Text(
          'Tổng quan đánh giá',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF424656),
          ),
        ),
        _SummaryGrid(
          patient: p,
          assessmentState: assessmentState,
          onAssessmentTap: onAssessmentTap,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assessment tab
// ─────────────────────────────────────────────────────────────────────────────
class _AssessmentTab extends ConsumerStatefulWidget {
  const _AssessmentTab({required this.caseId});

  final String caseId;

  @override
  ConsumerState<_AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends ConsumerState<_AssessmentTab> {
  DateTime? _selectedDate;

  DateTime _toVietnamTime(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 7));
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  List<AssessmentDetail> _filteredHistory(List<AssessmentDetail> history) {
    final selectedDate = _selectedDate;

    if (selectedDate == null) {
      return history;
    }

    return history.where((item) {
      return _isSameDay(_toVietnamTime(item.evaluationDateTime), selectedDate);
    }).toList();
  }

  AssessmentDetail? _selectedDetail(
    AssessmentState state,
    List<AssessmentDetail> visibleHistory,
  ) {
    if (visibleHistory.isEmpty) {
      return null;
    }

    final selectedAssessmentId = state.selectedAssessmentId;
    if (selectedAssessmentId != null) {
      for (final item in visibleHistory) {
        if (item.assessmentId == selectedAssessmentId) {
          return item;
        }
      }
    }

    return visibleHistory.first;
  }

  Future<void> _pickAssessmentDate(List<AssessmentDetail> history) async {
    if (history.isEmpty) {
      return;
    }

    final sortedDates =
        history
            .map((item) => _toVietnamTime(item.evaluationDateTime))
            .map(
              (dateTime) =>
                  DateTime(dateTime.year, dateTime.month, dateTime.day),
            )
            .toSet()
            .toList()
          ..sort();

    final initialDate = _selectedDate ?? sortedDates.last;

    DateTime? pickedDate;

    try {
      pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: sortedDates.first,
        lastDate: sortedDates.last,
        helpText: 'Chọn ngày đánh giá',
        cancelText: 'Hủy',
        confirmText: 'Chọn',
        initialEntryMode: DatePickerEntryMode.calendarOnly,
      );
    } catch (_) {
      return;
    }

    if (!mounted || pickedDate == null) {
      return;
    }

    final confirmedDate = pickedDate;

    setState(() {
      _selectedDate = DateTime(
        confirmedDate.year,
        confirmedDate.month,
        confirmedDate.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(
      assessmentNotifierProvider(widget.caseId),
    );
    if (assessmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (assessmentState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 72,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 16),
              Text(
                assessmentState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF424656)),
              ),
            ],
          ),
        ),
      );
    }

    final visibleHistory = _filteredHistory(assessmentState.history);
    final detail = _selectedDetail(assessmentState, visibleHistory);

    // Search bar always rendered so user can change/clear the date filter
    final searchBar = _AssessmentDateSearchBar(
      selectedDate: _selectedDate,
      onTap: () => _pickAssessmentDate(assessmentState.history),
      onClear: _selectedDate == null
          ? null
          : () {
              setState(() {
                _selectedDate = null;
              });
            },
    );

    if (detail == null) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: searchBar,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_note_outlined,
                      size: 72,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      assessmentState.history.isEmpty
                          ? 'Chưa có dữ liệu'
                          : 'Không có bài đánh giá trong ngày đã chọn',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424656),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        child: const Text('Xóa bộ lọc ngày'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        searchBar,
        const SizedBox(height: 16),
        if (visibleHistory.isNotEmpty)
          _AssessmentHistoryTimeline(
            caseId: widget.caseId,
            state: assessmentState,
            history: visibleHistory,
          ),
        const SizedBox(height: 16),

        ...detail.details.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AssessmentItemCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _AssessmentDateSearchBar extends StatelessWidget {
  const _AssessmentDateSearchBar({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  String _formatSelectedDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedDate == null
                    ? 'Chọn ngày đánh giá'
                    : _formatSelectedDate(selectedDate!),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191B24),
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Xóa bộ lọc ngày',
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF727687),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentHistoryTimeline extends ConsumerWidget {
  const _AssessmentHistoryTimeline({
    required this.caseId,
    required this.state,
    required this.history,
  });

  final String caseId;
  final AssessmentState state;
  final List<AssessmentDetail> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = history[index];

          final selected = item.assessmentId == state.selectedAssessmentId;

          return _AssessmentHistoryCard(
            assessment: item,
            selected: selected,
            onTap: () {
              ref
                  .read(assessmentNotifierProvider(caseId).notifier)
                  .selectAssessment(item.assessmentId);
            },
          );
        },
      ),
    );
  }
}

class _AssessmentHistoryCard extends StatelessWidget {
  const _AssessmentHistoryCard({
    required this.assessment,
    required this.selected,
    required this.onTap,
  });

  final AssessmentDetail assessment;
  final bool selected;
  final VoidCallback onTap;

  DateTime _toVietnamTime(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 7));
  }

  String _triageLabel(String triageColor) {
    return switch (triageColor.toUpperCase()) {
      'GREEN' => 'Xanh',
      'YELLOW' => 'Vàng',
      'RED' => 'Đỏ',
      _ => triageColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final vietnamTime = _toVietnamTime(assessment.evaluationDateTime);
    final date = DateFormat('dd/MM').format(vietnamTime);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffEEF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xffE2E8F0),
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.w700)),

            const SizedBox(height: 6),

            _AssessmentColorDot(assessment.triageColor),

            const SizedBox(height: 4),

            Text(
              _triageLabel(assessment.triageColor),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),

            Text(
              '${assessment.totalScore} điểm',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentColorDot extends StatelessWidget {
  const _AssessmentColorDot(this.triageColor);

  final String triageColor;

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (triageColor.toUpperCase()) {
      case 'GREEN':
        color = Colors.green;
        break;

      case 'YELLOW':
        color = Colors.orange;
        break;

      case 'RED':
        color = Colors.red;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AssessmentItemCard extends StatelessWidget {
  const _AssessmentItemCard({required this.item});

  final AssessmentDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            item.questionText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191B24),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.optionText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF424656),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${item.scoreEarned}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
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
// Notes tab (mock data, replace with real api called when available)
// ─────────────────────────────────────────────────────────────────────────────
class _PatientNote {
  const _PatientNote({
    required this.author,
    required this.createdAt,
    required this.content,
  });

  final String author;
  final DateTime createdAt;
  final String content;
}

final _mockNotes = <_PatientNote>[
  _PatientNote(
    author: 'ĐD. Nguyễn Thị Hoa',
    createdAt: DateTime(2026, 7, 14, 9, 30),
    content:
        'Bệnh nhân buồn nôn nhiều sau bữa sáng. Đã thông báo bác sĩ trực để theo dõi thêm.',
  ),
  _PatientNote(
    author: 'BS. Trần Văn Nam',
    createdAt: DateTime(2026, 7, 13, 18, 15),
    content:
        'Tiếp tục theo dõi triệu chứng tiêu hóa. Chưa chỉ định can thiệp thêm.',
  ),
  _PatientNote(
    author: 'ĐD. Nguyễn Thị Hoa',
    createdAt: DateTime(2026, 7, 13, 8, 20),
    content:
        'Người bệnh hợp tác tốt, đã hoàn thành khảo sát triệu chứng trong ngày.',
  ),
];

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes});

  final List<_PatientNote> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final note = notes[index];

        return _NoteCard(note: note);
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final _PatientNote note;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('dd/MM/yyyy • HH:mm').format(note.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.author,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF191B24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const Divider(height: 24),
          Text(
            note.content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF424656),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info grid
// ─────────────────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.patient});
  final PatientSummary patient;

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

              if (patient.bmi != null)
                _InfoRow(label: 'BMI', value: patient.bmi!.toStringAsFixed(1)),

              if (patient.surgeryDate != null)
                _InfoRow(
                  label: 'Ngày phẫu thuật',
                  value: patient.surgeryDate!,
                  isLast: true,
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _InfoCard(
          title: 'Thông tin phẫu thuật',
          child: Column(
            children: [
              if (patient.diagnosis != null)
                _InfoRow(label: 'Chẩn đoán', value: patient.diagnosis!),

              if (patient.surgeryType != null)
                _InfoRow(label: 'Loại phẫu thuật', value: patient.surgeryType!),

              if (patient.operationMethod != null)
                _InfoRow(
                  label: 'Phương pháp mổ',
                  value: patient.operationMethod!,
                ),

              _InfoRow(
                label: 'Có miệng nối tiêu hóa',
                value: patient.hasGiAnastomosis == null
                    ? 'Chưa cập nhật'
                    : (patient.hasGiAnastomosis! ? 'Có' : 'Không'),
                isLast: true,
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

// ignore: unused_element
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
  const _SummaryGrid({
    required this.patient,
    required this.assessmentState,
    required this.onAssessmentTap,
  });

  final PatientSummary patient;
  final AssessmentState assessmentState;
  final VoidCallback onAssessmentTap;

  @override
  Widget build(BuildContext context) {
    final score = assessmentState.detail?.totalScore;
    final assessmentStr = score == null ? '-' : '$score điểm';
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
          onTap: onAssessmentTap,
        ),
        _SummaryCard(
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.error,
          label: 'CẢNH BÁO',
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
          label: 'HẬU PHẪU',
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
    this.onTap,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
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
        ),
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
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_outlined, size: 20),
              label: const Text('Thông báo bác sĩ'),
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

// ignore: unused_element
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
