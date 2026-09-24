import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet_prefill.dart';
import 'package:poms/features/nurse/presentation/providers/treatment_order_provider.dart';
import 'package:poms/shared/widgets/app_text_field.dart';
import 'package:poms/shared/widgets/disease_multi_select_field.dart';

/// Mở form "Thêm phiếu theo dõi điều trị" (chỉ bác sĩ).
///
/// Trả về mức chăm sóc (1/2/3) vừa được chỉ định thành công, hoặc null nếu
/// người dùng hủy / gửi thất bại.
Future<int?> showTreatmentOrderSheet(
  BuildContext context, {
  required String caseId,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.95,
      child: TreatmentOrderSheet(caseId: caseId),
    ),
  );
}

const _textDark = Color(0xFF191B24);
const _textMuted = Color(0xFF424656);
const _border = Color(0xFFC2C6D8);
const _disabledFill = Color(0xFFE2E4EC);

/// "Phiếu theo dõi điều trị". Phần hành chính (tờ số, cơ sở, khoa, họ tên,
/// tuổi, giới tính, phòng, giường) do máy chủ tự điền và chỉ để xem. Bác sĩ
/// nhập mức chăm sóc (không có mặc định), thời gian, diễn biến bệnh (điền sẵn
/// chỉ số sinh tồn gần nhất) và chỉ định; có thể chỉnh chẩn đoán / bệnh kèm
/// theo. Phiếu được máy chủ lưu sang HIS.
class TreatmentOrderSheet extends ConsumerStatefulWidget {
  const TreatmentOrderSheet({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<TreatmentOrderSheet> createState() =>
      _TreatmentOrderSheetState();
}

class _TreatmentOrderSheetState extends ConsumerState<TreatmentOrderSheet> {
  /// Không có giá trị mặc định — bác sĩ buộc phải chọn rõ ràng.
  CareLevel? _selectedLevel;

  /// "Thời gian" — cố tình không tự điền.
  DateTime? _recordedAt;

  String? _diagnosis;

  /// "Bệnh kèm theo" — nhãn ICD, như form thêm người bệnh.
  List<String> _comorbidities = const [];

  final _progressController = TextEditingController();
  final _instructionsController = TextEditingController();

  bool _prefillApplied = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _progressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _applyPrefill(TreatmentSheetPrefill prefill) {
    if (_prefillApplied) return;
    _prefillApplied = true;
    _progressController.text = prefill.progressNotes;
    _comorbidities = prefill.comorbidities;
    _diagnosis = prefill.diagnosis;
  }

  Future<void> _pickRecordedAt() async {
    final now = DateTime.now();
    final initial = _recordedAt ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Chọn giờ',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (time == null || !mounted) return;

    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? get _recordedAtError {
    final value = _recordedAt;
    if (value == null) return 'Vui lòng chọn thời gian';
    if (value.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return 'Thời gian không được ở tương lai';
    }
    return null;
  }

  bool get _isValid =>
      _selectedLevel != null &&
      _recordedAtError == null &&
      _progressController.text.trim().isNotEmpty &&
      _instructionsController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    if (!_isValid) return;

    final level = _selectedLevel!;

    final order = await ref
        .read(treatmentOrderNotifierProvider(widget.caseId).notifier)
        .submit(
          careLevel: level,
          instructions: _instructionsController.text.trim(),
          sheet: TreatmentSheetInput(
            recordedAt: _recordedAt!,
            progressNotes: _progressController.text.trim(),
            diagnosis: _diagnosis?.trim(),
            comorbidities: _comorbidities,
          ),
        );

    if (!mounted || order == null) return;

    Navigator.of(context).pop(level.value);
  }

  @override
  Widget build(BuildContext context) {
    final prefillAsync = ref.watch(
      treatmentSheetPrefillProvider(widget.caseId),
    );
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thêm phiếu theo dõi điều trị',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: prefillAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _PrefillError(
                onRetry: () => ref.invalidate(
                  treatmentSheetPrefillProvider(widget.caseId),
                ),
              ),
              data: (prefill) {
                _applyPrefill(prefill);
                return _buildForm(prefill);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(TreatmentSheetPrefill prefill) {
    final state = ref.watch(treatmentOrderNotifierProvider(widget.caseId));
    final submitting = state.isSubmitting;

    final diagnosisOptions = <String>{
      if (_diagnosis != null && _diagnosis!.isNotEmpty) _diagnosis!,
      ...prefill.diagnosisOptions,
    }.toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;

                Widget pair(Widget left, Widget right) => wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 16),
                          Expanded(child: right),
                        ],
                      )
                    : Column(
                        children: [left, const SizedBox(height: 12), right],
                      );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.errorMessage != null) ...[
                      _ErrorBanner(message: state.errorMessage!),
                      const SizedBox(height: 12),
                    ],

                    // ── Phần hành chính (tự điền) ──
                    _ReadOnlyBox(
                      label: 'Tờ số',
                      value: '${prefill.sheetNumber}',
                    ),
                    const SizedBox(height: 12),
                    pair(
                      _ReadOnlyBox(
                        label: 'Cơ sở KC, CB',
                        value: prefill.facility,
                      ),
                      _ReadOnlyBox(
                        label: 'Họ và tên',
                        value: prefill.patientName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    pair(
                      _ReadOnlyBox(
                        label: 'Khoa',
                        value: prefill.department,
                        disabled: true,
                      ),
                      _ReadOnlyBox(
                        label: 'Mã số người bệnh',
                        value: prefill.caseId,
                      ),
                    ),
                    const SizedBox(height: 12),
                    pair(
                      DropdownButtonFormField<String>(
                        initialValue: _diagnosis?.isEmpty ?? true
                            ? null
                            : _diagnosis,
                        isExpanded: true,
                        decoration: _decoration('Chẩn đoán'),
                        items: diagnosisOptions
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) => setState(() => _diagnosis = value),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _ReadOnlyBox(
                              label: 'Tuổi',
                              value: prefill.age?.toString() ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ReadOnlyBox(
                              label: 'Giới tính',
                              value: prefill.gender ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    pair(
                      DiseaseMultiSelectField(
                        label: 'Bệnh kèm theo',
                        values: _comorbidities,
                        enabled: !submitting,
                        decoration: _decoration(null),
                        onChanged: (value) =>
                            setState(() => _comorbidities = value),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _ReadOnlyBox(
                              label: 'Phòng',
                              value: prefill.room ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ReadOnlyBox(
                              label: 'Số giường',
                              value: prefill.bed ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Mức chăm sóc ──
                    const SizedBox(height: 20),
                    const _SectionLabel('MỨC CHĂM SÓC *'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<CareLevel>(
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        segments: CareLevel.values
                            .map(
                              (level) => ButtonSegment<CareLevel>(
                                value: level,
                                label: Text(
                                  prefill.activeCareLevel == level
                                      ? '${level.label} (hiện tại)'
                                      : level.label,
                                ),
                              ),
                            )
                            .toList(),
                        selected: _selectedLevel == null
                            ? const <CareLevel>{}
                            : {_selectedLevel!},
                        onSelectionChanged: submitting
                            ? null
                            : (selection) => setState(
                                () => _selectedLevel = selection.isEmpty
                                    ? null
                                    : selection.first,
                              ),
                      ),
                    ),
                    if (_selectedLevel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _selectedLevel!.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                    if (_showErrors && _selectedLevel == null)
                      const _FieldError('Vui lòng chọn mức chăm sóc'),

                    // ── Thời gian ──
                    const SizedBox(height: 20),
                    const _SectionLabel('THỜI GIAN *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: submitting ? null : _pickRecordedAt,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _decoration(null).copyWith(
                          suffixIcon: const Icon(Icons.schedule_rounded),
                        ),
                        child: Text(
                          _recordedAt == null
                              ? 'Chọn ngày giờ khám'
                              : DateFormat(
                                  'HH:mm dd/MM/yyyy',
                                ).format(_recordedAt!),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: _recordedAt == null ? _textMuted : _textDark,
                          ),
                        ),
                      ),
                    ),
                    if (_showErrors && _recordedAtError != null)
                      _FieldError(_recordedAtError!),

                    // ── Diễn biến bệnh ──
                    const SizedBox(height: 20),
                    const _SectionLabel('DIỄN BIẾN BỆNH *'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _progressController,
                      keyboardType: TextInputType.multiline,
                      minLines: 6,
                      maxLines: 12,
                      enabled: !submitting,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prefill.latestVitalSignAt != null
                          ? 'Đã tự điền chỉ số sinh tồn gần nhất — có thể chỉnh sửa.'
                          : 'Người bệnh chưa có chỉ số sinh tồn nào được ghi nhận.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: _textMuted,
                      ),
                    ),
                    if (_showErrors && _progressController.text.trim().isEmpty)
                      const _FieldError('Vui lòng nhập diễn biến bệnh'),

                    // ── Chỉ định ──
                    const SizedBox(height: 20),
                    const _SectionLabel('CHỈ ĐỊNH *'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _instructionsController,
                      keyboardType: TextInputType.multiline,
                      minLines: 6,
                      maxLines: 12,
                      enabled: !submitting,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_showErrors &&
                        _instructionsController.text.trim().isEmpty)
                      const _FieldError('Vui lòng nhập chỉ định'),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ),

        // ── Hủy | Lưu ──
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

InputDecoration _decoration(String? label, {bool disabled = false}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _border),
  );
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: disabled ? _disabledFill : Colors.white,
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Ô chỉ đọc trông như ô nhập (giống bản giấy); `disabled` tô xám như "Khoa".
class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox({
    required this.label,
    required this.value,
    this.disabled = false,
  });

  final String label;
  final String value;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _decoration(label, disabled: disabled),
      child: Text(
        value.isEmpty ? '--' : value,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: _textDark,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: _textMuted,
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.error,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefillError extends StatelessWidget {
  const _PrefillError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: _textMuted),
          const SizedBox(height: 12),
          const Text(
            'Không tải được thông tin phiếu (kiểm tra kết nối HIS).',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', color: _textMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
