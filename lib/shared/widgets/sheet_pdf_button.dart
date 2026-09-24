import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import 'package:poms/core/utils/extensions.dart';

/// Nút "Tải PDF" cho các phiếu (phiếu điều trị, phiếu chăm sóc).
///
/// Tải file PDF máy chủ dựng theo mẫu giấy rồi mở bảng chia sẻ của hệ điều
/// hành (lưu vào Tệp, in, gửi Zalo/Email...).
class SheetPdfButton extends ConsumerStatefulWidget {
  const SheetPdfButton({required this.load, required this.fileName, super.key});

  /// Lấy nội dung PDF, vd `ref.read(repo).getCareSheetPdf(caseId, sheetId)`.
  final Future<Uint8List> Function(WidgetRef ref) load;
  final String fileName;

  @override
  ConsumerState<SheetPdfButton> createState() => _SheetPdfButtonState();
}

class _SheetPdfButtonState extends ConsumerState<SheetPdfButton> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      final bytes = await widget.load(ref);
      await Printing.sharePdf(bytes: bytes, filename: widget.fileName);
    } catch (e, st) {
      developer.log(
        'SheetPdfButton download error: $e',
        name: 'SheetPdfButton',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        context.showTopToast(
          'Không tải được PDF. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _download,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: Text(_loading ? 'Đang tải...' : 'Tải PDF'),
    );
  }
}
