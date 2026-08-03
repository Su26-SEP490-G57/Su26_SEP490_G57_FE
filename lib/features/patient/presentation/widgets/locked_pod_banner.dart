import 'package:flutter/material.dart';

import 'package:poms/features/patient/domain/models/current_pod.dart';

class LockedPodBanner extends StatelessWidget {
  const LockedPodBanner({required this.currentPod, super.key});

  final CurrentPod currentPod;

  @override
  Widget build(BuildContext context) {
    if (!currentPod.isLocked) return const SizedBox.shrink();

    final rawReason = currentPod.holdReason;
    final reason = _translateReason(rawReason);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB74D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_circle_filled_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến trình hồi phục đang tạm dừng',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason.isNotEmpty
                      ? 'Lý do: $reason\n\nBạn vẫn có thể tiếp tục xem hướng dẫn hiện tại và thực hiện khảo sát.'
                      : 'Hồ sơ của bạn đang được tạm dừng tiến trình POD. Bạn vẫn có thể tiếp tục xem hướng dẫn và làm khảo sát.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _translateReason(String? reason) {
    if (reason == null || reason.trim().isEmpty) return '';
    var text = reason.trim();
    if (text.contains('Auto-locked: Reached max POD with concerning health status')) {
      return 'Tự động tạm dừng: Đã đạt mốc ngày POD tối đa với mức độ sức khỏe cần theo dõi kỹ (Vàng/Đỏ).';
    }
    if (text.startsWith('Auto-locked:')) {
      text = text.replaceAll('Auto-locked:', 'Tự động tạm dừng:');
    }
    return text;
  }
}
