import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/utils/extensions.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/care_sheet.dart';
import 'package:poms/features/nurse/presentation/providers/care_observation_provider.dart';
import 'package:poms/features/nurse/presentation/widgets/care_sheet_form.dart';

const _textDark = Color(0xFF191B24);
const _textMuted = Color(0xFF424656);
const _border = Color(0xFFE1E3EE);

/// Danh sách "Phiếu theo dõi và chăm sóc" của người bệnh (lưu ở HIS), mới
/// nhất trước. Phiếu đã lưu chỉ xem, không sửa. `canCreate` = điều dưỡng /
/// điều dưỡng trưởng / bác sĩ — hiện nút "Thêm phiếu".
class CareSheetsList extends ConsumerWidget {
  const CareSheetsList({
    required this.caseId,
    required this.canCreate,
    super.key,
  });

  final String caseId;
  final bool canCreate;

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final saved = await showCareSheetForm(context, caseId: caseId);
    if (saved == null || !context.mounted) return;

    ref.invalidate(careSheetsProvider(caseId));
    context.showTopToast(
      'Đã lưu phiếu chăm sóc tờ số ${saved.sheetNumber}',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(careSheetsProvider(caseId));

    final addButton = canCreate
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openForm(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm phiếu chăm sóc'),
              ),
            ),
          )
        : null;

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ListView(
        children: [
          ?addButton,
          _Message(
            icon: Icons.cloud_off_rounded,
            text: 'Không tải được phiếu chăm sóc từ HIS.',
            action: OutlinedButton(
              onPressed: () => ref.invalidate(careSheetsProvider(caseId)),
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.refresh(careSheetsProvider(caseId).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ?addButton,
            if (list.sheets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: _Message(
                  icon: Icons.assignment_outlined,
                  text: 'Chưa có phiếu theo dõi và chăm sóc.',
                ),
              )
            else
              for (final sheet in list.sheets)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _CareSheetCard(sheet: sheet, form: list.form),
                ),
          ],
        ),
      ),
    );
  }
}

class _CareSheetCard extends StatelessWidget {
  const _CareSheetCard({required this.sheet, required this.form});

  final CareSheet sheet;
  final CareSheetForm form;

  String get _allergyText => switch (sheet.hasAllergy) {
    true => 'Có${sheet.allergyNote == null ? '' : ': ${sheet.allergyNote}'}',
    false => 'Chưa ghi nhận',
    null => '--',
  };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm dd/MM/yyyy');

    // Chỉ các mục đã ghi, theo thứ tự trên phiếu giấy.
    final filledSections = [
      for (final section in form.sections)
        (
          section: section,
          fields: [
            for (final field in section.fields)
              if ((sheet.content[section.contentKey(field)] ?? '').isNotEmpty)
                (
                  label: field.label,
                  value: sheet.content[section.contentKey(field)]!,
                ),
          ],
        ),
    ].where((entry) => entry.fields.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          '${form.titleOf(sheet.sheetType)} · Tờ số ${sheet.sheetNumber}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${dateFormat.format(sheet.recordedAt)} · ${sheet.nurseName ?? '--'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: _textMuted,
            ),
          ),
        ),
        children: [
          _InfoRow('Cơ sở KC, CB', sheet.facility),
          _InfoRow('Khoa', sheet.department),
          _InfoRow('Số vào viện', sheet.admissionNumber),
          _InfoRow('Mã người bệnh', sheet.patientCode),
          _InfoRow('Họ và tên', sheet.patientName),
          _InfoRow(
            'Tuổi / Giới tính',
            '${sheet.age ?? '--'} / ${sheet.gender ?? '--'}',
          ),
          _InfoRow(
            'Phòng / Giường',
            '${sheet.room ?? '--'} / ${sheet.bed ?? '--'}',
          ),
          _InfoRow('Chẩn đoán', sheet.diagnosis),
          _InfoRow('Tiền sử dị ứng', _allergyText),
          _InfoRow('Phân cấp chăm sóc', sheet.careLevel?.label),
          for (final entry in filledSections) ...[
            const Divider(height: 24),
            Text(
              entry.section.title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            for (final field in entry.fields)
              _InfoRow(field.label, field.value),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value == null || value!.trim().isEmpty ? '--' : value!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: _textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

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
