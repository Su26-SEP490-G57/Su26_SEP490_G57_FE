import 'package:flutter/material.dart';
import 'package:poms/core/constants/app_colors.dart';

/// Premium pagination bar with:
/// - Swipe hint text
/// - Page dot indicators (max 7 visible)
/// - Prev / current / next pill display
/// - Smooth animated dot transitions
class PatientPagination extends StatelessWidget {
  const PatientPagination({
    required this.currentPage,
    required this.totalPages,
    required this.startIndex,
    required this.endIndex,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final int startIndex;
  final int endIndex;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      // Only show count text when there's no pagination needed.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            'Hiển thị $total người bệnh',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Count label ───────────────────────────────────────────────
        Text(
          'Hiển thị $startIndex–$endIndex / $total người bệnh',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 12),

        // ── Page nav row ──────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prev button
            _NavButton(
              icon: Icons.chevron_left_rounded,
              enabled: currentPage > 1,
              onTap: onPrevious,
            ),

            const SizedBox(width: 12),

            // Dot indicators
            _PageDots(currentPage: currentPage, totalPages: totalPages),

            const SizedBox(width: 12),

            // Next button
            _NavButton(
              icon: Icons.chevron_right_rounded,
              enabled: currentPage < totalPages,
              onTap: onNext,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Swipe hint ────────────────────────────────────────────────
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swipe_rounded,
              size: 14,
              color: Color(0xFFBBBEC8),
            ),
            SizedBox(width: 4),
            Text(
              'Vuốt để chuyển trang',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFFBBBEC8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated dot row — shows up to 7 dots with shrinking edges
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.currentPage, required this.totalPages});

  final int currentPage;
  final int totalPages;

  static const int _maxVisible = 7;

  @override
  Widget build(BuildContext context) {
    final visible = totalPages.clamp(1, _maxVisible);

    // Window of pages to show
    int start;
    if (totalPages <= _maxVisible) {
      start = 1;
    } else {
      start = (currentPage - (_maxVisible ~/ 2)).clamp(1, totalPages - _maxVisible + 1);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visible, (i) {
        final page = start + i;
        final isActive = page == currentPage;
        final isEdge = totalPages > _maxVisible &&
            (i == 0 && start > 1 || i == visible - 1 && start + visible - 1 < totalPages);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : (isEdge ? 6 : 8),
          height: isActive ? 8 : (isEdge ? 6 : 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : isEdge
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFFBFC2D0),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav button
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.25)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}
