import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/nurse/domain/models/care_level.dart';
import 'package:poms/features/nurse/domain/models/treatment_sheet.dart';
import 'package:poms/features/nurse/presentation/providers/treatment_order_provider.dart';
import 'package:poms/shared/widgets/sheet_pdf_button.dart';

const _textDark = Color(0xFF191B24);
const _textMuted = Color(0xFF424656);
const _border = Color(0xFFE1E3EE);

/// Tab "Phiếu điều trị" — danh sách phiếu theo dõi điều trị của người bệnh
/// (lưu ở HIS), mới nhất trước. Nút "Thêm phiếu điều trị" ở đầu tab (giống
/// tab Phiếu chăm sóc) chỉ hiện khi có [onAdd] — tức là bác sĩ.
class TreatmentSheetsTab extends ConsumerWidget {
  const TreatmentSheetsTab({required this.caseId, this.onAdd, super.key});

  final String caseId;

  /// Mở form lập phiếu mới; null = không được lập phiếu (chỉ xem).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetsAsync = ref.watch(treatmentSheetsProvider(caseId));

    Future<void> refresh() =>
        ref.refresh(treatmentSheetsProvider(caseId).future);

    final addButton = onAdd != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm phiếu điều trị'),
              ),
            ),
          )
        : null;

    return sheetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ListView(
        children: [
          ?addButton,
          _Message(
            icon: Icons.cloud_off_rounded,
            text: 'Không tải được phiếu điều trị từ HIS.',
            action: OutlinedButton(
              onPressed: () => ref.invalidate(treatmentSheetsProvider(caseId)),
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
      data: (sheets) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ?addButton,
            if (sheets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: _Message(
                  icon: Icons.description_outlined,
                  text: 'Chưa có phiếu theo dõi điều trị.',
                ),
              )
            else
              for (final sheet in sheets)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SheetCard(sheet: sheet),
                ),
          ],
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.sheet});

  final TreatmentSheet sheet;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm dd/MM/yyyy');

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
        title: Row(
          children: [
            Text(
              'Tờ số ${sheet.sheetNumber}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            if (sheet.careLevel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  sheet.careLevel!.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${dateFormat.format(sheet.recordedAt)} · ${sheet.doctorName ?? '--'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: _textMuted,
            ),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SheetPdfButton(
              fileName:
                  'phieu-dieu-tri-${sheet.patientCode}-to-${sheet.sheetNumber}.pdf',
              load: (ref) => ref
                  .read(treatmentOrderRepositoryProvider)
                  .getTreatmentSheetPdf(sheet.patientCode, sheet.sheetId),
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow('Cơ sở KC, CB', sheet.facility),
          _InfoRow('Khoa', sheet.department),
          _InfoRow('Họ và tên', sheet.patientName),
          _InfoRow('Mã số người bệnh', sheet.patientCode),
          _InfoRow(
            'Tuổi / Giới tính',
            '${sheet.age ?? '--'} / ${sheet.gender ?? '--'}',
          ),
          _InfoRow(
            'Phòng / Giường',
            '${sheet.room ?? '--'} / ${sheet.bed ?? '--'}',
          ),
          _InfoRow('Chẩn đoán', sheet.diagnosis),
          _InfoRow('Bệnh kèm theo', sheet.comorbidities),
          const Divider(height: 24),
          _Block('DIỄN BIẾN BỆNH', sheet.progressNotes),
          const SizedBox(height: 12),
          _Block('CHỈ ĐỊNH', sheet.orders),
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
            width: 130,
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

class _Block extends StatelessWidget {
  const _Block(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            height: 1.4,
            color: _textDark,
          ),
        ),
      ],
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
