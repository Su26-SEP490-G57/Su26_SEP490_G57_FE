import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/presentation/providers/treatment_order_provider.dart';
import 'package:poms/shared/widgets/app_text_field.dart';

/// Mở bottom sheet "Chỉ định điều trị" (chỉ bác sĩ).
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
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => TreatmentOrderSheet(caseId: caseId),
  );
}

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

  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final level = _selectedLevel;
    if (level == null) return;

    final instructions = _instructionsController.text.trim();

    final order = await ref
        .read(treatmentOrderNotifierProvider(widget.caseId).notifier)
        .submit(
          careLevel: level,
          instructions: instructions.isEmpty ? null : instructions,
        );

    if (!mounted) return;

    Navigator.of(context).pop(order == null ? null : level.value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentOrderNotifierProvider(widget.caseId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC2C6D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chỉ định điều trị',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF191B24),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chọn mức chăm sóc cho người bệnh. Hệ thống sẽ tự gán phiếu theo '
              'dõi chăm sóc tương ứng cho điều dưỡng.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF424656),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'MỨC CHĂM SÓC *',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF424656),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<CareLevel>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: CareLevel.values
                  .map(
                    (level) => ButtonSegment<CareLevel>(
                      value: level,
                      label: Text(level.label),
                    ),
                  )
                  .toList(),
              selected: _selectedLevel == null
                  ? const <CareLevel>{}
                  : {_selectedLevel!},
              onSelectionChanged: state.isSubmitting
                  ? null
                  : (selection) => setState(
                      () => _selectedLevel = selection.isEmpty
                          ? null
                          : selection.first,
                    ),
            ),
            if (_selectedLevel != null) ...[
              const SizedBox(height: 8),
              Text(
                _selectedLevel!.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.secondary,
                ),
              ),
            ],

            const SizedBox(height: 16),
            AppTextField(
              controller: _instructionsController,
              label: 'Y lệnh / ghi chú (không bắt buộc)',
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              enabled: !state.isSubmitting,
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLevel == null || state.isSubmitting
                    ? null
                    : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu chỉ định'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
