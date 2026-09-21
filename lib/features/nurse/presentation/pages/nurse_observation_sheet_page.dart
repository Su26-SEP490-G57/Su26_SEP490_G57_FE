import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/utils/extensions.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/care_observation_sheet.dart';
import 'package:poms/features/nurse/presentation/providers/care_observation_provider.dart';
import 'package:poms/shared/widgets/app_text_field.dart';

/// Màn hình điền phiếu theo dõi chăm sóc của một người bệnh.
///
/// Bảng kiểm được render generic từ `checklistItems` mà máy chủ trả về, theo
/// `inputType` của từng mục (checkbox / number / văn bản tự do).
class NurseObservationSheetPage extends ConsumerStatefulWidget {
  const NurseObservationSheetPage({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<NurseObservationSheetPage> createState() =>
      _NurseObservationSheetPageState();
}

class _NurseObservationSheetPageState
    extends ConsumerState<NurseObservationSheetPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _checkboxValues = <String, bool>{};
  final _noteController = TextEditingController();

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(String key) {
    return _controllers.putIfAbsent(key, TextEditingController.new);
  }

  Future<void> _submit(CareObservationTask task) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final findings = <String, String>{
      for (final item in task.checklistItems)
        item.key: item.isCheckbox
            ? ((_checkboxValues[item.key] ?? false) ? 'true' : 'false')
            : _controllerFor(item.key).text.trim(),
    };

    final note = _noteController.text.trim();

    final entry = await ref
        .read(careObservationNotifierProvider(widget.caseId).notifier)
        .submitEntry(findings: findings, note: note.isEmpty ? null : note);

    if (!mounted) return;

    if (entry == null) {
      context.showTopToast(
        'Không thể lưu phiếu theo dõi. Vui lòng thử lại.',
        isError: true,
      );
      return;
    }

    for (final controller in _controllers.values) {
      controller.clear();
    }
    setState(_checkboxValues.clear);
    _noteController.clear();

    context.showTopToast('Đã hoàn thành phiếu theo dõi', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(careObservationNotifierProvider(widget.caseId));
    final task = state.task;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Phiếu theo dõi chăm sóc',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && task == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (task == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage ??
                      'Chưa có phiếu theo dõi cho người bệnh.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF424656),
                  ),
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _TaskHeader(task: task),
                const SizedBox(height: 16),

                if (task.checklistItems.isEmpty)
                  const Text(
                    'Phiếu này chưa có mục theo dõi nào.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF424656),
                    ),
                  )
                else
                  ...task.checklistItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: item.isCheckbox
                          ? _ChecklistCheckboxField(
                              label: item.label,
                              value: _checkboxValues[item.key] ?? false,
                              onChanged: (value) => setState(
                                () => _checkboxValues[item.key] = value,
                              ),
                            )
                          : AppTextField(
                              controller: _controllerFor(item.key),
                              label: item.label,
                              keyboardType: item.isNumber
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true,
                                    )
                                  : TextInputType.multiline,
                              minLines: item.isNumber ? null : 1,
                              maxLines: item.isNumber ? 1 : 3,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Vui lòng nhập nội dung theo dõi'
                                  : null,
                            ),
                    ),
                  ),

                AppTextField(
                  controller: _noteController,
                  label: 'Ghi chú chung (không bắt buộc)',
                  keyboardType: TextInputType.multiline,
                  minLines: 2,
                  maxLines: 4,
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting || task.checklistItems.isEmpty
                        ? null
                        : () => _submit(task),
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Hoàn thành'),
                  ),
                ),

                if (task.entries.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'LẦN GHI NHẬN TRƯỚC',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF424656),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...task.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EntryCard(task: task, entry: entry),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistCheckboxField extends StatelessWidget {
  const _ChecklistCheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC2C6D8)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF191B24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final CareObservationTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.sheetLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã hồ sơ: ${task.caseId}'
            '${task.careLevelAtAssignment == null ? '' : ' · Mức chăm sóc ${task.careLevelAtAssignment!.label}'}'
            ' · ${task.statusLabel}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.task, required this.entry});

  final CareObservationTask task;
  final CareObservationEntry entry;

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(entry.observedAt.toLocal());

    final labels = {
      for (final item in task.checklistItems) item.key: item.label,
    };
    final checkboxKeys = {
      for (final item in task.checklistItems)
        if (item.isCheckbox) item.key,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C6D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timestamp,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191B24),
            ),
          ),
          const SizedBox(height: 8),
          ...entry.findings.entries.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${labels[finding.key] ?? finding.key}: '
                '${checkboxKeys.contains(finding.key) ? (finding.value == 'true' ? 'Có' : 'Không') : finding.value}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF424656),
                ),
              ),
            ),
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.note!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF424656),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Theo dõi bởi ${entry.observedByName ?? 'Không rõ'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF6B6F80),
            ),
          ),
        ],
      ),
    );
  }
}
