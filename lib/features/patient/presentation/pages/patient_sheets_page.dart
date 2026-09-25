import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/presentation/providers/care_observation_provider.dart';
import 'package:poms/features/nurse/presentation/providers/treatment_order_provider.dart';

/// Loại phiếu bệnh nhân được xem (chỉ đọc) — mở từ thẻ "Thông tin phục hồi".
enum PatientSheetKind { treatment, care }

extension on PatientSheetKind {
  String get title => switch (this) {
    PatientSheetKind.treatment => 'Phiếu điều trị',
    PatientSheetKind.care => 'Phiếu chăm sóc',
  };

  String get emptyText => switch (this) {
    PatientSheetKind.treatment => 'Chưa có phiếu điều trị nào.',
    PatientSheetKind.care => 'Chưa có phiếu chăm sóc nào.',
  };

  String get filePrefix => switch (this) {
    PatientSheetKind.treatment => 'phieu-dieu-tri',
    PatientSheetKind.care => 'phieu-cham-soc',
  };
}

/// 1 dòng trong danh sách — gộp chung phiếu điều trị và phiếu chăm sóc.
class _SheetItem {
  const _SheetItem({
    required this.sheetId,
    required this.sheetNumber,
    required this.title,
    required this.recordedAt,
    required this.author,
  });

  final int sheetId;
  final int sheetNumber;
  final String title;
  final DateTime recordedAt;
  final String? author;
}

/// Danh sách phiếu của CHÍNH bệnh nhân đang đăng nhập (caseId lấy từ hồ sơ
/// đăng nhập), mới nhất lên đầu. Bấm 1 phiếu → xem PDF theo mẫu giấy.
class PatientSheetsPage extends ConsumerWidget {
  const PatientSheetsPage({required this.kind, super.key});

  final PatientSheetKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseId = ref.watch(authNotifierProvider).user?.caseId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          kind.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: caseId == null || caseId.isEmpty
          ? const _Message(
              icon: Icons.person_off_outlined,
              text: 'Không tìm thấy hồ sơ bệnh án của bạn.',
            )
          : _SheetList(kind: kind, caseId: caseId),
    );
  }
}

class _SheetList extends ConsumerWidget {
  const _SheetList({required this.kind, required this.caseId});

  final PatientSheetKind kind;
  final String caseId;

  AsyncValue<List<_SheetItem>> _watchItems(WidgetRef ref) {
    switch (kind) {
      case PatientSheetKind.treatment:
        return ref
            .watch(treatmentSheetsProvider(caseId))
            .whenData(
              (sheets) => sheets
                  .map(
                    (s) => _SheetItem(
                      sheetId: s.sheetId,
                      sheetNumber: s.sheetNumber,
                      title: 'Phiếu theo dõi điều trị',
                      recordedAt: s.recordedAt,
                      author: s.doctorName,
                    ),
                  )
                  .toList(),
            );
      case PatientSheetKind.care:
        return ref
            .watch(careSheetsProvider(caseId))
            .whenData(
              (list) => list.sheets
                  .map(
                    (s) => _SheetItem(
                      sheetId: s.sheetId,
                      sheetNumber: s.sheetNumber,
                      title: list.form.titleOf(s.sheetType),
                      recordedAt: s.recordedAt,
                      author: s.nurseName,
                    ),
                  )
                  .toList(),
            );
    }
  }

  void _refresh(WidgetRef ref) {
    switch (kind) {
      case PatientSheetKind.treatment:
        ref.invalidate(treatmentSheetsProvider(caseId));
      case PatientSheetKind.care:
        ref.invalidate(careSheetsProvider(caseId));
    }
  }

  Future<Uint8List> _loadPdf(WidgetRef ref, int sheetId) {
    return switch (kind) {
      PatientSheetKind.treatment =>
        ref
            .read(treatmentOrderRepositoryProvider)
            .getTreatmentSheetPdf(caseId, sheetId),
      PatientSheetKind.care =>
        ref
            .read(careObservationRepositoryProvider)
            .getCareSheetPdf(caseId, sheetId),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('HH:mm · dd/MM/yyyy');

    return _watchItems(ref).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _Message(
        icon: Icons.cloud_off_rounded,
        text: 'Không tải được ${kind.title.toLowerCase()}.',
        onRetry: () => _refresh(ref),
      ),
      data: (items) {
        // Sắp theo ngày ghi phiếu, mới nhất lên đầu (HIS trả theo số tờ).
        final sorted = [...items]
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

        return RefreshIndicator(
          onRefresh: () async => _refresh(ref),
          child: sorted.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    _Message(
                      icon: Icons.description_outlined,
                      text: kind.emptyText,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = sorted[index];
                    return _SheetTile(
                      item: item,
                      isLatest: index == 0,
                      subtitle: [
                        dateFormat.format(item.recordedAt),
                        if (item.author != null && item.author!.isNotEmpty)
                          item.author!,
                      ].join(' · '),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _SheetPdfViewerPage(
                            title: '${kind.title} — Tờ ${item.sheetNumber}',
                            fileName:
                                '${kind.filePrefix}-$caseId-to-${item.sheetNumber}.pdf',
                            load: () => _loadPdf(ref, item.sheetId),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.item,
    required this.isLatest,
    required this.subtitle,
    required this.onTap,
  });

  final _SheetItem item;
  final bool isLatest;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLatest
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Tờ số ${item.sheetNumber} · ${item.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Mới nhất',
                              style: TextStyle(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Xem PDF do máy chủ dựng theo mẫu giấy, ngay trong app (có nút in / chia sẻ).
class _SheetPdfViewerPage extends StatefulWidget {
  const _SheetPdfViewerPage({
    required this.title,
    required this.fileName,
    required this.load,
  });

  final String title;
  final String fileName;
  final Future<Uint8List> Function() load;

  @override
  State<_SheetPdfViewerPage> createState() => _SheetPdfViewerPageState();
}

class _SheetPdfViewerPageState extends State<_SheetPdfViewerPage> {
  late Future<Uint8List> _pdf = widget.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdf,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              icon: Icons.error_outline_rounded,
              text: 'Không tải được PDF. Vui lòng thử lại.',
              onRetry: () => setState(() => _pdf = widget.load()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = snapshot.data!;
          return PdfPreview(
            build: (_) async => bytes,
            pdfFileName: widget.fileName,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
