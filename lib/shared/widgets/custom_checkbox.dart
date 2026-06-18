import 'package:flutter/material.dart';

/// Custom checkbox không dùng Material Checkbox (tránh MouseRegion bug
/// trên Flutter Windows desktop — flutter/flutter#138627)
class CustomCheckbox extends StatelessWidget {
  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.activeColor = const Color(0xFF0050CB),
    this.borderColor = const Color(0xFFC2C6D8),
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final Color activeColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom box — no MouseRegion
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? activeColor : borderColor,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF424656),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
