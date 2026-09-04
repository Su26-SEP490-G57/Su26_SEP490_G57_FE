import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';
import 'package:poms/features/nurse/domain/models/assessment_detail.dart';
import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';
import 'package:poms/features/nurse/presentation/providers/alert_provider.dart';
import 'package:poms/features/nurse/presentation/providers/analytics_provider.dart';
import 'package:poms/features/nurse/presentation/providers/assessment_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/utils/extensions.dart';
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
  bool _isUpdatingCare = false;
  bool _isHandlingAlert = false;

  static const _tabs = ['Tổng quan', 'Lịch sử đánh giá', 'Ghi chú', 'Tuân thủ'];

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

  Future<void> _runCareAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isUpdatingCare = true);

    try {
      await action();
      await ref.read(patientNotifierProvider.notifier).loadPatients(limit: 100);
      ref.invalidate(patientPodStatusProvider(widget.patientId));
      if (!mounted) return;
      context.showTopToast(successMessage, isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      context.showTopToast(
        'Không thể cập nhật tình trạng người bệnh',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingCare = false);
    }
  }

  Future<String?> _requestHoldReason() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _HoldReasonDialog(),
    );

    return reason;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _togglePodLock(bool isLocked) async {
    if (isLocked) {
      final confirmed = await _confirm(
        title: 'Tiếp tục mức ăn',
        message: 'Cho phép tiếp tục tiến trình mức ăn cho người bệnh?',
        confirmLabel: 'Tiếp tục',
      );
      if (!confirmed) return;
      await _runCareAction(() async {
        await ref
            .read(patientRemoteDatasourceProvider)
            .setPodLock(caseId: widget.patientId, isLocked: false);
        // Tự động ghi nhận log vào tab Ghi chú
        await ref
            .read(assessmentNotifierProvider(widget.patientId).notifier)
            .submitReassessment(
              nurseNote: '▶️ Cho phép tiếp tục tiến trình ăn cho người bệnh',
              source: 'NOTE',
            );
      }, 'Đã tiếp tục mức ăn');
      return;
    }

    final reason = await _requestHoldReason();
    if (reason == null) return;
    await _runCareAction(() async {
      await ref
          .read(patientRemoteDatasourceProvider)
          .setPodLock(
            caseId: widget.patientId,
            isLocked: true,
            holdReason: reason,
          );
      // Tự động ghi nhận log vào tab Ghi chú
      await ref
          .read(assessmentNotifierProvider(widget.patientId).notifier)
          .submitReassessment(
            nurseNote: '⏸ Tạm dừng mức ăn. Lý do: $reason',
            source: 'NOTE',
          );
    }, 'Đã tạm dừng mức ăn');
  }

  Future<void> _rollbackDietLevel(PatientSummary patient) async {
    if (patient.dietLevel <= 0) return;
    final nextLevel = patient.dietLevel - 1;
    final confirmed = await _confirm(
      title: 'Lùi mức ăn',
      message: 'Chuyển mức ăn từ ${patient.dietLevel} về mức $nextLevel?',
      confirmLabel: 'Xác nhận',
    );
    if (!confirmed) return;

    await _runCareAction(() async {
      await ref
          .read(patientRemoteDatasourceProvider)
          .updateDietLevel(caseId: widget.patientId, dietLevel: nextLevel);
      // Tự động ghi nhận log vào tab Ghi chú
      await ref
          .read(assessmentNotifierProvider(widget.patientId).notifier)
          .submitReassessment(
            nurseNote:
                '⏪ Lùi chế độ ăn từ mức ${patient.dietLevel} về mức $nextLevel',
            source: 'NOTE',
          );
    }, 'Đã lùi mức ăn về mức $nextLevel');
  }

  Future<void> _acknowledgeAlert(AlertModel alert) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) =>
          _ConfirmHandledDialog(alertType: alert.alertType),
    );

    if (result == null || !mounted) return;

    final nurseAction = result['nurseAction'] ?? '';
    final nursingNote = result['nursingNote'] ?? '';

    setState(() => _isHandlingAlert = true);
    try {
      await ref
          .read(alertRemoteDataSourceProvider)
          .acknowledgeAlert(
            alertId: alert.alertId,
            nurseAction: nurseAction.isNotEmpty ? nurseAction : null,
            nursingNote: nursingNote.isNotEmpty ? nursingNote : null,
          );
      // Tự động tạo bản ghi ghi chú lâm sàng hiển thị trong tab Ghi chú
      final parts = <String>[];
      if (nurseAction.isNotEmpty) parts.add('Hành động: $nurseAction');
      if (nursingNote.isNotEmpty) parts.add('Ghi chú: $nursingNote');
      final noteContent = parts.isNotEmpty
          ? '✅ Đã xử trí cảnh báo ${alert.alertType == 'RED' ? 'ĐỎ' : 'VÀNG'}. ${parts.join('. ')}'
          : '✅ Đã xử trí cảnh báo ${alert.alertType == 'RED' ? 'ĐỎ' : 'VÀNG'}';

      await ref
          .read(assessmentNotifierProvider(widget.patientId).notifier)
          .submitReassessment(nurseNote: noteContent, source: 'NOTE');

      // Cập nhật trạng thái trong-bộ-nhớ + reload danh sách
      ref.read(alertsNotifierProvider.notifier).markHandled(alert.alertId);
      ref.invalidate(activeAlertForPatientProvider(widget.patientId));
      await ref.read(patientNotifierProvider.notifier).loadPatients(limit: 100);
      if (!mounted) return;
      context.showTopToast('Đã xác nhận xử trí thành công', isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      context.showTopToast(
        'Không thể cập nhật trạng thái xử trí',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isHandlingAlert = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final livePatient = ref.watch(patientByIdProvider(widget.patientId));
    final assessmentState = ref.watch(
      assessmentNotifierProvider(widget.patientId),
    );
    final podStatusAsync = ref.watch(
      patientPodStatusProvider(widget.patientId),
    );
    final activeAlertAsync = ref.watch(
      activeAlertForPatientProvider(widget.patientId),
    );
    final patient =
        livePatient ??
        widget.patient ??
        kMockPatients.firstWhere(
          (p) => p.code == widget.patientId,
          orElse: () => kMockPatients.first,
        );

    // Có alert (vàng hoặc đỏ) → hiện nút xác nhận
    final activeAlert = activeAlertAsync.asData?.value;
    final hasAlert = activeAlert != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Pinned AppBar ──
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
              'Chi tiết',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                tooltip: 'Thêm ghi chú',
                onPressed: () => _handleAddNote(patient),
              ),
            ],
          ),

          // ── Hero section ──
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

          // ── TabBar sticky ──
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
              activeAlert: activeAlert,
              onAssessmentTap: () => _tabController.animateTo(1),
            ),
            _AssessmentTab(caseId: widget.patientId),
            _NotesTab(caseId: widget.patientId),
            _ComplianceTab(caseId: widget.patientId),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        dietLevel: patient.dietLevel,
        isPodLocked: podStatusAsync.asData?.value.isLocked,
        isLoading: _isUpdatingCare || podStatusAsync.isLoading,
        isHandlingAlert: _isHandlingAlert,
        activeAlert: hasAlert ? activeAlert : null,
        onPodLockPressed: podStatusAsync.asData == null
            ? null
            : () => _togglePodLock(podStatusAsync.asData!.value.isLocked),
        onDietRollback: patient.dietLevel > 0
            ? () => _rollbackDietLevel(patient)
            : null,
        onAcknowledge: hasAlert ? () => _acknowledgeAlert(activeAlert) : null,
        onReassess: () => _handleReassess(patient),
      ),
    );
  }

  Future<void> _handleReassess(PatientSummary patient) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) =>
          _ReassessmentDialog(caseId: widget.patientId, patient: patient),
    );

    if (result == null || !mounted) return;

    final triageColor = result['triageColor'] as String;
    final noteText = result['note'] as String;

    String statusLabel;
    PatientStatus patientStatus;
    if (triageColor == 'RED') {
      statusLabel = 'Nguy cấp';
      patientStatus = PatientStatus.red;
    } else if (triageColor == 'YELLOW') {
      statusLabel = 'Cần theo dõi';
      patientStatus = PatientStatus.yellow;
    } else {
      statusLabel = 'Ổn định';
      patientStatus = PatientStatus.green;
    }

    // 1. Gửi API tới server để lưu vào CSDL (PostgreSQL)
    final newAssessment = await ref
        .read(assessmentNotifierProvider(widget.patientId).notifier)
        .submitReassessment(
          triageColor: triageColor,
          nurseNote: noteText.isNotEmpty ? noteText : null,
        );

    // 2. Cập nhật trạng thái người bệnh và danh sách cảnh báo trong FE
    ref
        .read(patientNotifierProvider.notifier)
        .patchPatient(
          widget.patientId,
          status: patientStatus,
          needsIntervention: triageColor != 'GREEN',
        );
    ref.read(alertsNotifierProvider.notifier).load();
    ref.invalidate(activeAlertForPatientProvider(widget.patientId));

    if (!mounted) return;

    if (newAssessment != null) {
      _tabController.animateTo(1);
      context.showTopToast(
        'Đã cập nhật đánh giá lại: $statusLabel',
        isSuccess: true,
      );
    } else {
      context.showTopToast(
        'Không thể lưu đánh giá lại. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  Future<void> _handleAddNote(PatientSummary patient) async {
    final noteText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddNoteDialog(),
    );

    if (noteText == null || noteText.trim().isEmpty || !mounted) return;

    // Gửi API lưu ghi chú đơn thuần (source = 'NOTE', không đổi triage color của bệnh nhân)
    final newAssessment = await ref
        .read(assessmentNotifierProvider(widget.patientId).notifier)
        .submitReassessment(nurseNote: noteText.trim(), source: 'NOTE');

    if (!mounted) return;

    if (newAssessment != null) {
      context.showTopToast(
        'Đã lưu ghi chú lâm sàng vào cơ sở dữ liệu',
        isSuccess: true,
      );
    } else {
      context.showTopToast(
        'Không thể lưu ghi chú. Vui lòng thử lại.',
        isError: true,
      );
    }
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog();

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thêm ghi chú lâm sàng',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú này sẽ được lưu vào cơ sở dữ liệu và hiển thị ở tab Ghi chú.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú diễn biến lâm sàng, chỉ định theo dõi...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(context).pop(text);
          },
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Lưu ghi chú'),
        ),
      ],
    );
  }
}

class _HoldReasonDialog extends StatefulWidget {
  const _HoldReasonDialog();

  @override
  State<_HoldReasonDialog> createState() => _HoldReasonDialogState();
}

class _HoldReasonDialogState extends State<_HoldReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạm dừng mức ăn'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: 'Lý do tạm dừng',
          hintText: 'Ví dụ: Người bệnh chưa dung nạp tốt chế độ ăn hiện tại',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) return;
            Navigator.of(context).pop(value);
          },
          child: const Text('Tạm dừng'),
        ),
      ],
    );
  }
}

class _ConfirmHandledDialog extends StatefulWidget {
  const _ConfirmHandledDialog({required this.alertType});

  final String alertType;

  @override
  State<_ConfirmHandledDialog> createState() => _ConfirmHandledDialogState();
}

class _ConfirmHandledDialogState extends State<_ConfirmHandledDialog> {
  late final TextEditingController _actionController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _actionController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _actionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRed = widget.alertType.toUpperCase() == 'RED';
    final levelLabel = isRed ? '🔴 Mức ĐỎ' : '🟡 Mức VÀNG';

    return AlertDialog(
      title: const Text('Xác nhận đã xử trí'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bệnh nhân $levelLabel — Xác nhận đã can thiệp và hoàn thành xử trí?',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: 'Hành động đã thực hiện (tùy chọn)',
                hintText:
                    'VD: Báo bác sĩ, điều chỉnh mức ăn, xử trí theo phác đồ...',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú điều dưỡng (tùy chọn)',
                hintText: 'Ghi chú thêm nếu cần...',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006E2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop({
              'nurseAction': _actionController.text.trim(),
              'nursingNote': _noteController.text.trim(),
            });
          },
          child: const Text('Xác nhận đã xử trí'),
        ),
      ],
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

  // String _displayPod(String pod) {
  //   return pod.replaceFirst(RegExp(r'^POD\s*', caseSensitive: false), 'POD ');
  // }

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
                size: 40,
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
                      patient.name,
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
                          'Mức ${patient.dietLevel}${patient.surgeryType != null ? ' - ${patient.surgeryType}' : ''}',
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
    this.activeAlert,
  });

  final PatientSummary? patient;
  final AssessmentState assessmentState;
  final VoidCallback onAssessmentTap;
  final AlertModel? activeAlert;

  @override
  Widget build(BuildContext context) {
    if (patient == null) {
      return const Center(child: Text('Không có thông tin bệnh nhân'));
    }
    final p = patient!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 220),
      children: [
        _InfoGrid(patient: p),
        const SizedBox(height: 16),

        // if (p.needsIntervention || activeAlert != null) ...[
        //   _AlertBanner(patient: p, activeAlert: activeAlert),
        //   const SizedBox(height: 16),
        // ],
        // _SummaryGrid(
        //   patient: p,
        //   assessmentState: assessmentState,
        //   onAssessmentTap: onAssessmentTap,
        // ),
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

class _DayGroup {
  const _DayGroup({required this.date, required this.assessments});

  final DateTime date;
  final List<AssessmentDetail> assessments;

  AssessmentDetail get latestAssessment => assessments.last;
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

  List<_DayGroup> _buildDayGroups(List<AssessmentDetail> history) {
    // Chỉ lấy bài đánh giá khảo sát (SURVEY) và đánh giá lại (REASSESSMENT).
    // Ghi chú đơn thuần (NOTE) sẽ hiển thị ở Tab Ghi chú.
    final assessmentHistory = history
        .where((item) => item.source != 'NOTE')
        .toList();

    if (assessmentHistory.isEmpty) return [];

    final map = <DateTime, List<AssessmentDetail>>{};
    for (final item in assessmentHistory) {
      final vnTime = _toVietnamTime(item.evaluationDateTime);
      final dayKey = DateTime(vnTime.year, vnTime.month, vnTime.day);
      map.putIfAbsent(dayKey, () => []).add(item);
    }

    // Ngày tăng dần (xếp từ trái sang phải: ngày cũ ở trái, ngày mới ở phải)
    final sortedDates = map.keys.toList()..sort();

    return sortedDates.map((date) {
      final list = map[date]!;
      // Sắp xếp các bài trong ngày theo giờ tăng dần -> bài cuối cùng là bài mới nhất trong ngày
      list.sort((a, b) => a.evaluationDateTime.compareTo(b.evaluationDateTime));
      return _DayGroup(date: date, assessments: list);
    }).toList();
  }

  Future<void> _pickAssessmentDate(List<_DayGroup> dayGroups) async {
    if (dayGroups.isEmpty) {
      return;
    }

    final sortedDates = dayGroups.map((g) => g.date).toList()..sort();
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

    final matchGroup = dayGroups.firstWhere(
      (g) => _isSameDay(g.date, confirmedDate),
      orElse: () => dayGroups.last,
    );
    ref
        .read(assessmentNotifierProvider(widget.caseId).notifier)
        .selectAssessment(matchGroup.latestAssessment.assessmentId);
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

    final dayGroups = _buildDayGroups(assessmentState.history);

    final searchBar = _AssessmentDateSearchBar(
      selectedDate: _selectedDate,
      onTap: () => _pickAssessmentDate(dayGroups),
      onClear: _selectedDate == null
          ? null
          : () {
              setState(() {
                _selectedDate = null;
              });
            },
    );

    if (dayGroups.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: searchBar,
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 72,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có dữ liệu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF424656)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    _DayGroup? selectedDayGroup;
    if (_selectedDate != null) {
      final index = dayGroups.indexWhere(
        (g) => _isSameDay(g.date, _selectedDate!),
      );
      if (index != -1) {
        selectedDayGroup = dayGroups[index];
      }
    } else {
      if (assessmentState.selectedAssessmentId != null) {
        final index = dayGroups.indexWhere(
          (g) => g.assessments.any(
            (a) => a.assessmentId == assessmentState.selectedAssessmentId,
          ),
        );
        if (index != -1) {
          selectedDayGroup = dayGroups[index];
        }
      }
      selectedDayGroup ??= dayGroups.last;
    }

    if (selectedDayGroup == null) {
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
                    const Text(
                      'Không có bài đánh giá trong ngày đã chọn',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF424656)),
                    ),
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
                ),
              ),
            ),
          ),
        ],
      );
    }

    AssessmentDetail activeDetail = selectedDayGroup.latestAssessment;
    if (assessmentState.selectedAssessmentId != null) {
      final match = selectedDayGroup.assessments.firstWhere(
        (a) => a.assessmentId == assessmentState.selectedAssessmentId,
        orElse: () => selectedDayGroup!.latestAssessment,
      );
      activeDetail = match;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        searchBar,
        const SizedBox(height: 16),

        _AssessmentHistoryTimeline(
          caseId: widget.caseId,
          activeDate: selectedDayGroup.date,
          dayGroups: dayGroups,
          onSelectDay: (group) {
            setState(() {
              _selectedDate = group.date;
            });
            ref
                .read(assessmentNotifierProvider(widget.caseId).notifier)
                .selectAssessment(group.latestAssessment.assessmentId);
          },
        ),

        if (selectedDayGroup.assessments.length > 1) ...[
          const SizedBox(height: 8),
          _AssessmentIntraDayTimeSelector(
            assessments: selectedDayGroup.assessments,
            selectedAssessmentId: activeDetail.assessmentId,
            onSelectAssessment: (assessmentId) {
              ref
                  .read(assessmentNotifierProvider(widget.caseId).notifier)
                  .selectAssessment(assessmentId);
            },
          ),
        ],

        const SizedBox(height: 8),

        if (activeDetail.details.isEmpty)
          _ReassessmentNoAnswersCard(assessment: activeDetail)
        else
          ...activeDetail.details.map(
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
    final hasDate = selectedDate != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: hasDate ? 5 : 10,
        ),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.event_rounded,
              size: hasDate ? 16 : 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDate
                    ? _formatSelectedDate(selectedDate!)
                    : 'Chọn ngày đánh giá',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: hasDate ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF191B24),
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF727687),
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF727687),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentHistoryTimeline extends StatefulWidget {
  const _AssessmentHistoryTimeline({
    required this.caseId,
    required this.activeDate,
    required this.dayGroups,
    required this.onSelectDay,
  });

  final String caseId;
  final DateTime activeDate;
  final List<_DayGroup> dayGroups;
  final ValueChanged<_DayGroup> onSelectDay;

  @override
  State<_AssessmentHistoryTimeline> createState() =>
      _AssessmentHistoryTimelineState();
}

class _AssessmentHistoryTimelineState
    extends State<_AssessmentHistoryTimeline> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveDate());
  }

  @override
  void didUpdateWidget(covariant _AssessmentHistoryTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeDate != widget.activeDate ||
        oldWidget.dayGroups.length != widget.dayGroups.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToActiveDate(),
      );
    }
  }

  void _scrollToActiveDate() {
    if (!_scrollController.hasClients || widget.dayGroups.isEmpty) return;

    final index = widget.dayGroups.indexWhere(
      (g) => _isSameDay(g.date, widget.activeDate),
    );

    if (index == -1) return;

    if (index == widget.dayGroups.length - 1) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      const itemWidth = 70.0;
      const separatorWidth = 12.0;
      final targetOffset = index * (itemWidth + separatorWidth);
      final maxExtent = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxExtent);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.dayGroups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final group = widget.dayGroups[index];
          final selected = _isSameDay(group.date, widget.activeDate);

          return _AssessmentHistoryCard(
            dayGroup: group,
            selected: selected,
            onTap: () => widget.onSelectDay(group),
          );
        },
      ),
    );
  }
}

class _AssessmentHistoryCard extends StatelessWidget {
  const _AssessmentHistoryCard({
    required this.dayGroup,
    required this.selected,
    required this.onTap,
  });

  final _DayGroup dayGroup;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM').format(dayGroup.date);
    final repAssessment = dayGroup.latestAssessment;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 70,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffEEF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xffE2E8F0),
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateStr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : const Color(0xFF191B24),
              ),
            ),
            const SizedBox(height: 3),
            _AssessmentColorDot(repAssessment.triageColor),
          ],
        ),
      ),
    );
  }
}

class _AssessmentIntraDayTimeSelector extends StatefulWidget {
  const _AssessmentIntraDayTimeSelector({
    required this.assessments,
    required this.selectedAssessmentId,
    required this.onSelectAssessment,
  });

  final List<AssessmentDetail> assessments;
  final int selectedAssessmentId;
  final ValueChanged<int> onSelectAssessment;

  @override
  State<_AssessmentIntraDayTimeSelector> createState() =>
      _AssessmentIntraDayTimeSelectorState();
}

class _AssessmentIntraDayTimeSelectorState
    extends State<_AssessmentIntraDayTimeSelector> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelectedTime(),
    );
  }

  @override
  void didUpdateWidget(covariant _AssessmentIntraDayTimeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAssessmentId != widget.selectedAssessmentId ||
        oldWidget.assessments.length != widget.assessments.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSelectedTime(),
      );
    }
  }

  void _scrollToSelectedTime() {
    if (!_scrollController.hasClients || widget.assessments.isEmpty) return;

    final index = widget.assessments.indexWhere(
      (a) => a.assessmentId == widget.selectedAssessmentId,
    );

    if (index == -1) return;

    if (index == widget.assessments.length - 1) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      const estimatedWidth = 75.0;
      final targetOffset = index * estimatedWidth;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxExtent);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  DateTime _toVietnamTime(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 7));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'Thời gian:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.assessments.map((a) {
                  final isSel = a.assessmentId == widget.selectedAssessmentId;
                  final timeStr = DateFormat(
                    'HH:mm',
                  ).format(_toVietnamTime(a.evaluationDateTime));

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => widget.onSelectAssessment(a.assessmentId),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AssessmentColorDot(a.triageColor),
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
      width: 12,
      height: 12,
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
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 8),
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
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 10,
              //     vertical: 4,
              //   ),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFEAF2FF),
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes tab — hiển thị ghi chú đánh giá lại thực tế của điều dưỡng (bỏ mock data)
// ─────────────────────────────────────────────────────────────────────────────

class _PatientNote {
  const _PatientNote({
    required this.id,
    required this.caseId,
    required this.author,
    required this.createdAt,
    required this.statusLabel,
    required this.triageColor,
    required this.content,
  });

  final String id;
  final String caseId;
  final String author;
  final DateTime createdAt;
  final String statusLabel; // "Nguy cấp", "Cần theo dõi", "Ổn định"
  final String triageColor; // "RED", "YELLOW", "GREEN"
  final String content;
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentState = ref.watch(assessmentNotifierProvider(caseId));

    if (assessmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final noteItems = assessmentState.history
        .where(
          (item) =>
              item.source == 'REASSESSMENT' ||
              item.source == 'NOTE' ||
              (item.nurseNote != null && item.nurseNote!.isNotEmpty) ||
              item.details.isEmpty,
        )
        .toList();

    final notes = noteItems.map((item) {
      final isPlainNote = item.source == 'NOTE';
      final triage = item.triageColor.toUpperCase();
      final statusLabel = isPlainNote
          ? ''
          : (triage == 'RED'
                ? 'Nguy cấp'
                : (triage == 'YELLOW' ? 'Cần theo dõi' : 'Ổn định'));
      final content = (item.nurseNote != null && item.nurseNote!.isNotEmpty)
          ? item.nurseNote!
          : 'Đã cập nhật trạng thái người bệnh thành $statusLabel.';
      return _PatientNote(
        id: item.assessmentId.toString(),
        caseId: caseId,
        author: isPlainNote
            ? 'Điều dưỡng (Ghi chú lâm sàng)'
            : 'Điều dưỡng (Đánh giá lại)',
        createdAt: item.evaluationDateTime.toUtc().add(
          const Duration(hours: 7),
        ),
        statusLabel: statusLabel,
        triageColor: triage,
        content: content,
      );
    }).toList();

    if (notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 72,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có ghi chú lâm sàng nào',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191B24),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Các ghi chú diễn biến lâm sàng và đánh giá lại của điều dưỡng sẽ hiển thị tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
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
    final hasStatusBadge = note.statusLabel.isNotEmpty;

    final isRed = note.triageColor.toUpperCase() == 'RED';
    final isYellow = note.triageColor.toUpperCase() == 'YELLOW';

    final badgeColor = hasStatusBadge
        ? (isRed
              ? const Color(0xFFEF4444)
              : (isYellow ? const Color(0xFFF59E0B) : const Color(0xFF10B981)))
        : const Color(0xFF64748B);
    final badgeBg = hasStatusBadge
        ? (isRed
              ? const Color(0xFFFEF2F2)
              : (isYellow ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)))
        : const Color(0xFFF1F5F9);

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
              if (hasStatusBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    note.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    '📝 Ghi chú',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
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
          const Divider(height: 20),
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
// Reassessment Dialog & Cards
// ─────────────────────────────────────────────────────────────────────────────

class _ReassessmentDialog extends StatefulWidget {
  const _ReassessmentDialog({required this.caseId, required this.patient});

  final String caseId;
  final PatientSummary patient;

  @override
  State<_ReassessmentDialog> createState() => _ReassessmentDialogState();
}

class _ReassessmentDialogState extends State<_ReassessmentDialog> {
  late final TextEditingController _noteController;

  String _selectedTriage = 'YELLOW';

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _noteController.addListener(_onNoteChanged);
    if (widget.patient.status == PatientStatus.red) {
      _selectedTriage = 'RED';
    } else if (widget.patient.status == PatientStatus.yellow) {
      _selectedTriage = 'YELLOW';
    } else {
      _selectedTriage = 'GREEN';
    }
  }

  void _onNoteChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasNote => _noteController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.rate_review_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đánh giá lại người bệnh',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Ghi chú đánh giá lại:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191B24),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'Nhập diễn biến lâm sàng hoặc lý do điều chỉnh trạng thái...',
                errorText: _hasNote ? null : 'Ghi chú là bắt buộc',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Text(
                  'Cập nhật trạng thái mới:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191B24),
                  ),
                ),
                if (!_hasNote) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '(Khóa)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            _StatusOptionTile(
              title: 'Nguy cấp',
              subtitle: 'Tương ứng Mức Đỏ',
              color: const Color(0xFFDC2626),
              icon: Icons.emergency_rounded,
              selected: _selectedTriage == 'RED',
              enabled: _hasNote,
              onTap: _hasNote
                  ? () => setState(() => _selectedTriage = 'RED')
                  : null,
            ),
            const SizedBox(height: 8),
            _StatusOptionTile(
              title: 'Cần theo dõi',
              subtitle: 'Tương ứng Mức Vàng',
              color: const Color(0xFFD97706),
              icon: Icons.warning_amber_rounded,
              selected: _selectedTriage == 'YELLOW',
              enabled: _hasNote,
              onTap: _hasNote
                  ? () => setState(() => _selectedTriage = 'YELLOW')
                  : null,
            ),
            const SizedBox(height: 8),
            _StatusOptionTile(
              title: 'Ổn định',
              subtitle: 'Tương ứng Mức Xanh',
              color: const Color(0xFF16A34A),
              icon: Icons.check_circle_rounded,
              selected: _selectedTriage == 'GREEN',
              enabled: _hasNote,
              onTap: _hasNote
                  ? () => setState(() => _selectedTriage = 'GREEN')
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasNote
                ? AppColors.primary
                : const Color(0xFFCBD5E1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _hasNote
              ? () {
                  Navigator.of(context).pop({
                    'triageColor': _selectedTriage,
                    'note': _noteController.text.trim(),
                  });
                }
              : null,
          child: const Text('Xác nhận đánh giá lại'),
        ),
      ],
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : const Color(0xFF94A3B8);

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected && enabled
                ? color.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected && enabled ? color : const Color(0xFFE2E8F0),
              width: selected && enabled ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: effectiveColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected && enabled
                            ? color
                            : const Color(0xFF191B24),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected && enabled)
                Icon(Icons.radio_button_checked_rounded, color: color, size: 20)
              else
                const Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReassessmentNoAnswersCard extends StatelessWidget {
  const _ReassessmentNoAnswersCard({required this.assessment});

  final AssessmentDetail assessment;

  DateTime _toVietnamTime(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 7));
  }

  @override
  Widget build(BuildContext context) {
    final vnTime = _toVietnamTime(assessment.evaluationDateTime);
    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(vnTime);

    final isRed = assessment.triageColor.toUpperCase() == 'RED';
    final isYellow = assessment.triageColor.toUpperCase() == 'YELLOW';

    final color = isRed
        ? const Color(0xFFDC2626)
        : (isYellow ? const Color(0xFFD97706) : const Color(0xFF16A34A));
    final label = isRed ? 'Nguy cấp' : (isYellow ? 'Cần theo dõi' : 'Ổn định');

    final noteContent =
        (assessment.nurseNote != null && assessment.nurseNote!.isNotEmpty)
        ? assessment.nurseNote!
        : 'Đã cập nhật trạng thái người bệnh thành $label.';

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
              Icon(Icons.rate_review_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đánh giá của y tá/bác sĩ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191B24),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Thời gian: $timeStr',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const Divider(height: 20),
          Text(
            noteContent,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF424656),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compliance tab — checklist + counters + bảng đánh giá cuối ngày (POD x câu hỏi)
// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceTab extends ConsumerWidget {
  const _ComplianceTab({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const Text(
          'ĐỘ TUÂN THỦ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF424656),
          ),
        ),
        const SizedBox(height: 10),
        _ComplianceStatsCard(caseId: caseId),
        const SizedBox(height: 24),
        const Text(
          'ĐÁNH GIÁ CUỐI NGÀY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF424656),
          ),
        ),
        const SizedBox(height: 10),
        _EndOfDayAssessmentCard(caseId: caseId),
      ],
    );
  }
}

class _ComplianceInfoCardShell extends StatelessWidget {
  const _ComplianceInfoCardShell({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _ComplianceEmptyState extends StatelessWidget {
  const _ComplianceEmptyState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _ComplianceInfoCardShell(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF727687),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplianceStatsCard extends ConsumerWidget {
  const _ComplianceStatsCard({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compliance = ref.watch(patientComplianceProvider(caseId));

    return compliance.when(
      loading: () => const _ComplianceInfoCardShell(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => _ComplianceEmptyState(
        message: 'Không thể tải dữ liệu tuân thủ',
        onRetry: () => ref.invalidate(patientComplianceProvider(caseId)),
      ),
      data: (data) => _ComplianceInfoCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checklist',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF727687),
                  ),
                ),
                _ComplianceStatusBadge(isCompliant: data.isDailyCompliant),
              ],
            ),
            const SizedBox(height: 10),
            _ChecklistRow(label: 'Hướng dẫn ăn', done: data.viewedGuidance),
            const SizedBox(height: 8),
            _ChecklistRow(
              label: 'Giáo dục sức khỏe',
              done: data.viewedEducation,
            ),
            const SizedBox(height: 8),
            _ChecklistRow(
              label: 'Đánh giá định kỳ',
              done:
                  data.morningAssessmentStatus ==
                      ScheduledAssessmentStatus.completed &&
                  data.afternoonAssessmentStatus ==
                      ScheduledAssessmentStatus.completed,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AssessmentSlotRow(
                    label: 'Khung giờ sáng (06:00 - 08:00)',
                    status: data.morningAssessmentStatus,
                  ),
                  const SizedBox(height: 6),
                  _AssessmentSlotRow(
                    label: 'Khung giờ chiều (16:00 - 18:00)',
                    status: data.afternoonAssessmentStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Số liệu',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF727687),
              ),
            ),
            const SizedBox(height: 10),
            _CounterRow(
              label: 'Số đánh giá đã hoàn thành',
              value: data.assessmentCompletedCount,
            ),
            const SizedBox(height: 8),
            _CounterRow(label: 'Số lần nhắc nhở', value: data.reminderCount),
            const SizedBox(height: 8),
            _CounterRow(
              label: 'Số lần truy cập ứng dụng',
              value: data.appAccessCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplianceStatusBadge extends StatelessWidget {
  const _ComplianceStatusBadge({required this.isCompliant});
  final bool isCompliant;

  @override
  Widget build(BuildContext context) {
    final color = isCompliant ? AppColors.statusNormal : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isCompliant ? 'Tuân thủ' : 'Không tuân thủ',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 18,
          color: done ? AppColors.statusNormal : const Color(0xFFC2C6D8),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: done ? const Color(0xFF191B24) : const Color(0xFF727687),
          ),
        ),
      ],
    );
  }
}

class _AssessmentSlotRow extends StatelessWidget {
  const _AssessmentSlotRow({required this.label, required this.status});

  final String label;
  final ScheduledAssessmentStatus? status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (status) {
      ScheduledAssessmentStatus.completed => (
        Icons.check_circle_rounded,
        AppColors.statusNormal,
        'Hoàn thành',
      ),
      ScheduledAssessmentStatus.missed => (
        Icons.cancel_rounded,
        AppColors.statusCritical,
        'Bỏ lỡ',
      ),
      ScheduledAssessmentStatus.pending => (
        Icons.circle_outlined,
        AppColors.statusWarning,
        'Chưa làm',
      ),
      null => (
        Icons.remove_circle_outline,
        AppColors.statusUnknown,
        'Chưa làm',
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF727687),
            ),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF424656),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191B24),
          ),
        ),
      ],
    );
  }
}

class _EndOfDayAssessmentCard extends ConsumerWidget {
  const _EndOfDayAssessmentCard({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrix = ref.watch(assessmentMatrixProvider(caseId));

    return matrix.when(
      loading: () => const _ComplianceInfoCardShell(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => _ComplianceEmptyState(
        message: 'Không thể tải bảng đánh giá',
        onRetry: () => ref.invalidate(assessmentMatrixProvider(caseId)),
      ),
      data: (matrix) {
        if (matrix.questions.isEmpty) {
          return const _ComplianceEmptyState(
            message: 'Chưa có đánh giá cuối ngày cho người bệnh này',
          );
        }
        return _ComplianceInfoCardShell(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _AssessmentMatrixTable(matrix: matrix),
          ),
        );
      },
    );
  }
}

class _AssessmentMatrixTable extends StatelessWidget {
  const _AssessmentMatrixTable({required this.matrix});
  final AssessmentMatrix matrix;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF424656),
    );
    const cellStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      color: Color(0xFF191B24),
    );

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 44,
      columnSpacing: 20,
      columns: [
        const DataColumn(label: Text('Chỉ số', style: headerStyle)),
        ...matrix.pods.map(
          (pod) => DataColumn(label: Text('POD$pod', style: headerStyle)),
        ),
      ],
      rows: matrix.questions.map((question) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 140,
                child: Text(
                  question.questionText,
                  style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ...matrix.pods.map(
              (pod) => DataCell(
                Text(
                  question.scoreForPod(pod)?.toString() ?? '--',
                  style: cellStyle,
                ),
              ),
            ),
          ],
        );
      }).toList(),
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
              _InfoRow(label: 'Mã hồ sơ', value: patient.code),

              if (patient.age != null)
                _InfoRow(label: 'Tuổi', value: '${patient.age}'),

              if (patient.gender != null)
                _InfoRow(label: 'Giới tính', value: patient.gender!),

              if (patient.bmi != null)
                _InfoRow(label: 'BMI', value: patient.bmi!.toStringAsFixed(1)),

              if (patient.surgeryDate != null)
                _InfoRow(
                  label: 'Ngày phẫu thuật',
                  value: '${patient.surgeryDate!} - ${patient.pod}',
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

// class _AlertBanner extends StatelessWidget {
//   const _AlertBanner({required this.patient, this.activeAlert});

//   final PatientSummary patient;
//   final AlertModel? activeAlert;

//   bool get _isRed => activeAlert?.alertType.toUpperCase() == 'RED';

//   @override
//   Widget build(BuildContext context) {
//     final alertColor = _isRed ? AppColors.error : const Color(0xFFA33200);
//     final alertBg = _isRed ? AppColors.errorContainer : const Color(0xFFFFF3E0);
//     final alertBorder = _isRed
//         ? AppColors.error.withValues(alpha: 0.2)
//         : const Color(0xFFA33200).withValues(alpha: 0.2);
//     final iconData = _isRed
//         ? Icons.emergency_rounded
//         : Icons.warning_amber_rounded;
//     final title = _isRed ? 'Cảnh báo khẩn: Mức ĐỎ' : 'Cần theo dõi: Mức VÀNG';
//     final subtitle = _isRed
//         ? 'Nhấn “Xác nhận đã xử trí” phía dưới để ghi nhận can thiệp.'
//         : 'Tiếp tục theo dõi triệu chứng bệnh nhân.';

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: alertBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: alertBorder),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               color: alertColor,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(iconData, color: Colors.white, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontFamily: 'Inter',
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: alertColor,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontFamily: 'Inter',
//                     fontSize: 11,
//                     color: alertColor,
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'ĐG gần nhất: ${patient.lastAssessmentTime ?? 'Chưa có'}',
//                   style: TextStyle(
//                     fontFamily: 'Inter',
//                     fontSize: 10.5,
//                     color: alertColor.withValues(alpha: 0.75),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────────────────────────────────────
// Summary grid
// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
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
    final triage = assessmentState.detail?.triageColor;
    final assessmentStr = triage == null
        ? '-'
        : (triage.toUpperCase() == 'GREEN'
              ? 'An toàn'
              : triage.toUpperCase() == 'YELLOW'
              ? 'Theo dõi'
              : 'Can thiệp');
    final assessmentValColor = triage == null
        ? const Color(0xFF191B24)
        : (triage.toUpperCase() == 'GREEN'
              ? const Color(0xFF006E2F)
              : triage.toUpperCase() == 'YELLOW'
              ? const Color(0xFF735C00)
              : AppColors.error);
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
          valueColor: assessmentValColor,
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
  const _BottomActionBar({
    required this.dietLevel,
    required this.isPodLocked,
    required this.isLoading,
    required this.isHandlingAlert,
    required this.onPodLockPressed,
    required this.onDietRollback,
    required this.onReassess,
    this.activeAlert,
    this.onAcknowledge,
  });

  final int dietLevel;
  final bool? isPodLocked;
  final bool isLoading;
  final bool isHandlingAlert;
  final VoidCallback? onPodLockPressed;
  final VoidCallback? onDietRollback;
  final VoidCallback onReassess;
  final AlertModel? activeAlert;
  final VoidCallback? onAcknowledge;

  bool get _hasAlert => activeAlert != null;

  @override
  Widget build(BuildContext context) {
    final isRedAlert = activeAlert?.alertType.toUpperCase() == 'RED';
    final safeAreaBottom = MediaQuery.of(context).viewPadding.bottom;
    // `NurseShell` injects its nav-bar height into `padding.bottom` for
    // scrollable content. Using it here adds an extra gap above the floating
    // navigation. Reserve only the nav bar's actual footprint instead.
    final navigationClearance =
        66.0 + (safeAreaBottom > 0 ? safeAreaBottom : 12.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, navigationClearance + 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(16),
        //   border: Border.all(color: const Color(0xFFC2C6D8), width: 0.8),
        //   boxShadow: [
        //     BoxShadow(
        //       color: const Color(0xFF00459A).withValues(alpha: 0.08),
        //       blurRadius: 16,
        //       offset: const Offset(0, 4),
        //     ),
        //     BoxShadow(
        //       color: Colors.black.withValues(alpha: 0.04),
        //       blurRadius: 6,
        //       offset: const Offset(0, 2),
        //     ),
        //   ],
        // ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Hàng 1: Xác nhận đã xử trí (chỉ xuất hiện khi có cảnh báo vàng hoặc đỏ) ──
            if (_hasAlert) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isHandlingAlert ? null : onAcknowledge,
                  icon: isHandlingAlert
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isHandlingAlert ? 'Đang xử lý...' : 'Xác nhận đã xử trí',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRedAlert
                        ? AppColors.error
                        : const Color(0xFFC05600),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFC2C6D8),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Hàng 2: [Lùi mức ăn] | [Tạm dừng mức ăn (ở giữa)] | [Đánh giá lại] ──
            Row(
              children: [
                // 1. Nút Lùi mức ăn
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onDietRollback,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9A3412),
                      disabledForegroundColor: const Color(0xFF9CA3AF),
                      side: const BorderSide(color: Color(0xFFF0B79D)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_rounded, size: 16),
                        const SizedBox(height: 2),
                        Text(
                          dietLevel > 0
                              ? 'Lùi mức ăn ($dietLevel→${dietLevel - 1})'
                              : 'Lùi mức ăn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Nút Tạm dừng / Tiếp tục mức ăn (ở GIỮA)
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onPodLockPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFC2C6D8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPodLocked == true
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 16,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPodLocked == true ? 'Tiếp tục ăn' : 'Tạm dừng ăn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Nút Đánh giá lại
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReassess,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 16),
                        SizedBox(height: 2),
                        Text(
                          'Đánh giá lại',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
