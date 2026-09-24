import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/care_sheet.dart';
import 'package:poms/features/nurse/presentation/providers/care_observation_provider.dart';

/// Mở form "Thêm phiếu theo dõi và chăm sóc" (điều dưỡng / điều dưỡng
/// trưởng). Trả về phiếu vừa lưu, hoặc null nếu huỷ.
Future<CareSheet?> showCareSheetForm(
  BuildContext context, {
  required String caseId,
}) {
  return showModalBottomSheet<CareSheet>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.95,
      child: CareSheetFormSheet(caseId: caseId),
    ),
  );
}

const _textDark = Color(0xFF191B24);
const _textMuted = Color(0xFF424656);
const _border = Color(0xFFC2C6D8);
const _disabledFill = Color(0xFFE2E4EC);

const _groupTitles = {
  CareSheetGroup.observation: 'Nhận định, theo dõi',
  CareSheetGroup.diagnosis: 'Chẩn đoán ĐD / Đánh giá mục tiêu',
  CareSheetGroup.intervention: 'Can thiệp điều dưỡng, bàn giao',
};

/// Ký hiệu nhanh theo "Quy ước ký hiệu" in trên phiếu.
const _quickSymbols = ['(+)', '(-)', '(/)'];

/// "Phiếu theo dõi và chăm sóc" (MS 38/BV1). Bố cục các mục do máy chủ trả
/// về (`form.sections`); phần hành chính tự điền và chỉ đọc. Điều dưỡng nhập
/// ngày giờ (không tự điền), số vào viện, tiền sử dị ứng và các mục theo dõi —
/// chỉ số sinh tồn gần nhất, cân nặng, BMI được điền sẵn.
class CareSheetFormSheet extends ConsumerStatefulWidget {
  const CareSheetFormSheet({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<CareSheetFormSheet> createState() => _CareSheetFormSheetState();
}

class _CareSheetFormSheetState extends ConsumerState<CareSheetFormSheet> {
  final _controllers = <String, TextEditingController>{};
  final _admissionController = TextEditingController();
  final _allergyNoteController = TextEditingController();

  DateTime? _recordedAt;

  /// null = không điền, false = chưa ghi nhận, true = có.
  bool? _hasAllergy;

  bool _prefillApplied = false;
  bool _showErrors = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _admissionController.dispose();
    _allergyNoteController.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  void _applyPrefill(CareSheetPrefill prefill) {
    if (_prefillApplied) return;
    _prefillApplied = true;
    prefill.content.forEach((key, value) => _controllerFor(key).text = value);
  }

  Map<String, String> get _content => {
    for (final entry in _controllers.entries)
      if (entry.value.text.trim().isNotEmpty)
        entry.key: entry.value.text.trim(),
  };

  String? get _recordedAtError {
    final value = _recordedAt;
    if (value == null) return 'Vui lòng chọn ngày giờ';
    if (value.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return 'Thời gian không được ở tương lai';
    }
    return null;
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _showErrors = true);

    final content = _content;
    if (_recordedAtError != null || content.isEmpty) return;

    final saved = await ref
        .read(careSheetSubmitProvider(widget.caseId).notifier)
        .submit(
          CareSheetInput(
            recordedAt: _recordedAt!,
            content: content,
            admissionNumber: _admissionController.text.trim(),
            hasAllergy: _hasAllergy,
            allergyNote: _allergyNoteController.text.trim(),
          ),
        );

    if (!mounted || saved == null) return;
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final prefillAsync = ref.watch(careSheetPrefillProvider(widget.caseId));
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
          Text(
            prefillAsync.valueOrNull == null
                ? 'Thêm phiếu theo dõi và chăm sóc'
                : prefillAsync.value!.form.titleOf(
                    prefillAsync.value!.sheetType,
                  ),
            style: const TextStyle(
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
              error: (_, _) => _CenteredMessage(
                icon: Icons.cloud_off_rounded,
                text: 'Không tải được thông tin phiếu (kiểm tra kết nối HIS).',
                action: OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(careSheetPrefillProvider(widget.caseId)),
                  child: const Text('Thử lại'),
                ),
              ),
              data: (prefill) {
                if (prefill.sheetType == null) {
                  return const _CenteredMessage(
                    icon: Icons.info_outline_rounded,
                    text:
                        'Người bệnh chưa được bác sĩ chỉ định mức chăm sóc nên '
                        'chưa lập phiếu chăm sóc được.',
                  );
                }
                _applyPrefill(prefill);
                return _buildForm(prefill);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(CareSheetPrefill prefill) {
    final submitState = ref.watch(careSheetSubmitProvider(widget.caseId));
    final submitting = submitState.isSubmitting;
    final form = prefill.form;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;

              Widget grid(List<Widget> children) {
                if (!wide) {
                  return Column(
                    children: [
                      for (final child in children) ...[
                        child,
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final child in children)
                      SizedBox(
                        width: (constraints.maxWidth - 16) / 2,
                        child: child,
                      ),
                  ],
                );
              }

              return ListView(
                children: [
                  if (submitState.errorMessage != null) ...[
                    _ErrorBanner(message: submitState.errorMessage!),
                    const SizedBox(height: 12),
                  ],

                  // ── Phần hành chính (tự điền) ──
                  grid([
                    _ReadOnlyBox('Tờ số', '${prefill.sheetNumber}'),
                    _ReadOnlyBox('Cơ sở KC, CB', prefill.facility),
                    _ReadOnlyBox('Khoa', prefill.department, disabled: true),
                    _ReadOnlyBox('Mã người bệnh', prefill.caseId),
                    _ReadOnlyBox('Họ và tên', prefill.patientName),
                    _ReadOnlyBox(
                      'Tuổi / Giới tính',
                      '${prefill.age ?? '--'} / ${prefill.gender ?? '--'}',
                    ),
                    _ReadOnlyBox(
                      'Phòng / Giường',
                      '${prefill.room ?? '--'} / ${prefill.bed ?? '--'}',
                    ),
                    _ReadOnlyBox('Chẩn đoán', prefill.diagnosis ?? ''),
                    _ReadOnlyBox(
                      'Phân cấp chăm sóc',
                      prefill.careLevel?.label ?? '',
                    ),
                    _ReadOnlyBox('Điều dưỡng thực hiện', prefill.nurseName),
                    TextField(
                      controller: _admissionController,
                      enabled: !submitting,
                      decoration: _decoration('Số vào viện'),
                    ),
                  ]),

                  // ── Tiền sử dị ứng ──
                  const SizedBox(height: 8),
                  const _SectionLabel('TIỀN SỬ DỊ ỨNG'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Chưa ghi nhận'),
                        selected: _hasAllergy == false,
                        onSelected: submitting
                            ? null
                            : (selected) => setState(
                                () => _hasAllergy = selected ? false : null,
                              ),
                      ),
                      ChoiceChip(
                        label: const Text('Có'),
                        selected: _hasAllergy == true,
                        onSelected: submitting
                            ? null
                            : (selected) => setState(
                                () => _hasAllergy = selected ? true : null,
                              ),
                      ),
                    ],
                  ),
                  if (_hasAllergy == true) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _allergyNoteController,
                      enabled: !submitting,
                      decoration: _decoration('Ghi rõ dị ứng'),
                    ),
                  ],

                  // ── Ngày giờ ──
                  const SizedBox(height: 20),
                  const _SectionLabel('NGÀY GIỜ *'),
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
                            ? 'Chọn ngày giờ'
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

                  // ── Quy ước ký hiệu ──
                  const SizedBox(height: 16),
                  Text(
                    'Quy ước ký hiệu: ${form.legend}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                  if (prefill.latestVitalSignAt != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Chỉ số sinh tồn gần nhất, cân nặng, BMI đã được điền sẵn '
                        '— có thể chỉnh sửa.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _textMuted,
                        ),
                      ),
                    ),

                  // ── Các mục theo dõi, nhóm theo cột trên phiếu giấy ──
                  for (final group in CareSheetGroup.values) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(_groupTitles[group]!.toUpperCase()),
                    const SizedBox(height: 8),
                    for (final section in form.sections.where(
                      (s) => s.group == group,
                    ))
                      _SectionTile(
                        section: section,
                        controllerFor: _controllerFor,
                        enabled: !submitting,
                        initiallyExpanded: section.fields.any(
                          (f) => prefill.content.containsKey(
                            section.contentKey(f),
                          ),
                        ),
                      ),
                  ],
                  if (_showErrors && _content.isEmpty)
                    const _FieldError('Vui lòng ghi ít nhất một mục theo dõi'),
                  const SizedBox(height: 16),
                ],
              );
            },
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

/// Một mục trên phiếu (VD "Hô hấp"), thu gọn được để form dài vẫn dễ dùng
/// trên điện thoại.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.controllerFor,
    required this.enabled,
    required this.initiallyExpanded,
  });

  final CareSheetSection section;
  final TextEditingController Function(String key) controllerFor;
  final bool enabled;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          section.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // ≥600px: 2 cột như bản giấy; điện thoại: 1 cột.
              final width = constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final field in section.fields)
                    SizedBox(
                      width: field.multiline ? constraints.maxWidth : width,
                      child: _CareSheetFieldInput(
                        field: field,
                        controller: controllerFor(section.contentKey(field)),
                        enabled: enabled,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CareSheetFieldInput extends StatelessWidget {
  const _CareSheetFieldInput({
    required this.field,
    required this.controller,
    required this.enabled,
  });

  final CareSheetField field;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Mọi ô đều nhiều dòng: phím Enter luôn xuống dòng (ô ngắn bắt đầu từ 1
    // dòng rồi tự giãn), không ô nào kết thúc nhập bằng Enter.
    final input = TextField(
      controller: controller,
      enabled: enabled,
      minLines: field.multiline ? 2 : 1,
      maxLines: field.multiline ? 8 : 4,
      maxLength: 2000,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: _decoration(field.label),
    );

    if (field.multiline) return input;

    return Row(
      children: [
        Expanded(child: input),
        const SizedBox(width: 4),
        for (final symbol in _quickSymbols)
          _SymbolButton(
            symbol: symbol,
            onTap: enabled ? () => controller.text = symbol : null,
          ),
      ],
    );
  }
}

class _SymbolButton extends StatelessWidget {
  const _SymbolButton({required this.symbol, this.onTap});

  final String symbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Text(
          symbol,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
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
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Ô chỉ đọc trông như ô nhập (giống bản giấy); `disabled` tô xám như "Khoa".
class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox(this.label, this.value, {this.disabled = false});

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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', color: _textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
