import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// BuildContext extensions
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : null,
      ),
    );
  }

  /// Hiển thị toast ở góc trên bên phải màn hình
  void showTopToast(
    String message, {
    bool isSuccess = false,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(this);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        isSuccess: isSuccess,
        isError: isError,
        onDismiss: () => entry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

/// String extensions
extension StringX on String {
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}

/// DateTime extensions
extension DateTimeX on DateTime {
  String get toDisplayDate => DateFormat('dd/MM/yyyy').format(this);
  String get toDisplayDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);
  String get toDisplayTime => DateFormat('HH:mm').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return toDisplayDate;
  }
}

/// Nullable extensions
extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Top toast widget
// ─────────────────────────────────────────────────────────────────────────────

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.onDismiss,
    required this.duration,
    this.isSuccess = false,
    this.isError = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final Duration duration;
  final bool isSuccess;
  final bool isError;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.isSuccess) return const Color(0xFF006E2F);
    if (widget.isError) return const Color(0xFFBA1A1A);
    return const Color(0xFF1A1B22);
  }

  IconData get _icon {
    if (widget.isSuccess) return Icons.check_circle_rounded;
    if (widget.isError) return Icons.error_rounded;
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
