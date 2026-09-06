import 'package:flutter/material.dart';
import 'package:poms/core/constants/app_colors.dart';

/// Trang thông báo dành cho bác sĩ.
/// Chỉ dùng để theo dõi các cập nhật xử trí từ điều dưỡng, không phải màn
/// hình theo dõi toàn bộ cảnh báo y tế trong bệnh viện.
class DoctorAlertsPage extends StatelessWidget {
  const DoctorAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mark_chat_read_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Thông báo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191B24),
                ),
              ),
              const SizedBox(height: 10),

              // Description
              const Text(
                'Nhận thông báo khi điều dưỡng hoàn thành xử trí để theo dõi diễn biến chăm sóc người bệnh.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF424656),
                ),
              ),
              const SizedBox(height: 28),

              // Context card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THÔNG TIN',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF727687),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildInfoItem(
                      Icons.check_circle_outline_rounded,
                      'Cập nhật hoàn thành xử trí từ điều dưỡng',
                      const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoItem(
                      Icons.people_outline_rounded,
                      'Hỗ trợ theo dõi lâm sàng và tra cứu hồ sơ bệnh nhân',
                      AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoItem(
                      Icons.schedule_rounded,
                      'Các cảnh báo y tế theo phòng sẽ được triển khai khi có cơ chế phân công phòng cho bác sĩ',
                      const Color(0xFFF57F17),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: Color(0xFF191B24),
            ),
          ),
        ),
      ],
    );
  }
}
