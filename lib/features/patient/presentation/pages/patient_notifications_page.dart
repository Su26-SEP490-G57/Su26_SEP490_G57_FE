import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';

class PatientNotificationsPage extends ConsumerStatefulWidget {
  const PatientNotificationsPage({super.key});

  @override
  ConsumerState<PatientNotificationsPage> createState() =>
      _PatientNotificationsPageState();
}

class _PatientNotificationsPageState
    extends ConsumerState<PatientNotificationsPage> {
  String _selectedFilter = 'all'; // 'all', 'medical', 'system'

  @override
  Widget build(BuildContext context) {
    final currentPodAsync = ref.watch(currentPodProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Thông báo hệ thống',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: 'Lịch sử đánh giá',
            onPressed: () => context.go(AppRoutes.patientAssessmentHistory),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentPodAsync.when(
        data: (pod) {
          final isLocked = pod?.isLocked ?? false;
          final holdReason = pod?.holdReason;

          return Column(
            children: [
              // Filter tabs
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả'),
                    const SizedBox(width: 8),
                    _buildFilterChip('medical', 'Khảo sát & Dinh dưỡng'),
                    const SizedBox(width: 8),
                    _buildFilterChip('system', 'Hệ thống'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Locked POD Alert Card (Highest Priority System Alert)
                    if (isLocked &&
                        (_selectedFilter == 'all' ||
                            _selectedFilter == 'system')) ...[
                      _buildLockedPodAlertCard(context, holdReason),
                      const SizedBox(height: 16),
                    ],

                    // Standard Notifications List
                    if (_selectedFilter == 'all' ||
                        _selectedFilter == 'medical') ...[
                      _buildNotificationItem(
                        icon: Icons.assignment_rounded,
                        iconBgColor: const Color(0xFFE6F9F1),
                        iconColor: const Color(0xFF10B981),
                        title: 'Nhắc nhở làm khảo sát hàng ngày',
                        body:
                            'Hãy hoàn thành bài đánh giá triệu chứng hôm nay để bác sĩ và điều dưỡng theo dõi tiến trình hồi phục của bạn.',
                        time: 'Hôm nay',
                        isUnread: true,
                        onTap: () => context.push(AppRoutes.patientAssessment),
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationItem(
                        icon: Icons.restaurant_menu_rounded,
                        iconBgColor: const Color(0xFFFFF7E6),
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Cập nhật hướng dẫn chế độ ăn',
                        body:
                            'Chế độ ăn uống và vận động khuyến nghị theo giao thức ERAS cho ngày hiện tại đã sẵn sàng.',
                        time: 'Hôm nay',
                        isUnread: false,
                        onTap: () =>
                            context.push(AppRoutes.patientDietGuidance),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_selectedFilter == 'all' ||
                        _selectedFilter == 'system') ...[
                      _buildNotificationItem(
                        icon: Icons.health_and_safety_rounded,
                        iconBgColor: AppColors.primaryContainer,
                        iconColor: AppColors.primary,
                        title: 'Hồ sơ bệnh án ERAS đã kích hoạt',
                        body:
                            'Tài khoản của bạn đã được kết nối thành công với giao thức theo dõi sau phẫu thuật.',
                        time: 'Vài ngày trước',
                        isUnread: false,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Không thể tải thông báo: $err')),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.primaryContainer,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : const Color(0xFFEDEDF9),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLockedPodAlertCard(BuildContext context, String? holdReason) {
    final reasonText = holdReason != null && holdReason.isNotEmpty
        ? holdReason
        : 'Đang trong quá trình theo dõi lâm sàng đặc biệt từ đội ngũ y tế.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến trình POD đang tạm dừng',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      'Thông báo hệ thống • Khóa POD',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFFF57C00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lý do: $reasonText\n\nLưu ý: Tiến trình POD hiện tại tạm thời giữ nguyên, tuy nhiên bạn vẫn có thể thực hiện bài khảo sát triệu chứng hàng ngày và xem hướng dẫn dinh dưỡng.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.45,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.patientAssessment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Làm khảo sát',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.patientDietGuidance),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100),
                    side: const BorderSide(color: Color(0xFFE65100)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.restaurant_rounded, size: 18),
                  label: const Text(
                    'Xem hướng dẫn',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.3)
                : const Color(0xFFEDEDF9),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
