import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/doctor/domain/models/doctor_notification.dart';
import 'package:poms/features/doctor/presentation/providers/doctor_notification_provider.dart';

/// Thông báo cho bác sĩ khi điều dưỡng chủ động tạm dừng mức ăn.
class DoctorAlertsPage extends ConsumerWidget {
  const DoctorAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The initial HTTP request remains the source of truth if the socket is
    // temporarily unavailable.
    ref.watch(doctorNotificationsRealtimeProvider);
    final notifications = ref.watch(doctorNotificationsProvider);

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
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _EmptyNotifications(),
        data: (alerts) {
          if (alerts.isEmpty) return const _EmptyNotifications();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(doctorNotificationsProvider);
              await ref.read(doctorNotificationsProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: alerts.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) return const _NotificationsHeader();

                final notification = alerts[index - 1];
                return _DoctorNotificationCard(
                  notification: notification,
                  onTap: () => context.push(
                    AppRoutes.doctorPatientDetailPath(notification.caseId),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Text(
        'Tạm dừng mức ăn từ điều dưỡng',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}

class _DoctorNotificationCard extends StatelessWidget {
  const _DoctorNotificationCard({
    required this.notification,
    required this.onTap,
  });

  final DoctorNotification notification;
  final VoidCallback onTap;

  String get _notificationTime {
    final time = notification.createdAt;
    if (time == null) return 'Vừa cập nhật';
    return DateFormat('HH:mm · dd/MM/yyyy').format(time.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final reason = notification.reason?.trim();
    final actorName = notification.actorName?.trim();
    final patientName = notification.patientName?.trim();
    final roomBed = notification.roomBed?.trim();
    final displayName = patientName == null || patientName.isEmpty
        ? notification.caseId
        : patientName;
    const iconColor = Color(0xFFA33200);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC2C6D8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pause_circle_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Điều dưỡng tạm dừng mức ăn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191B24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _notificationTime,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF727687),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Color(0xFF424656),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191B24),
                      ),
                    ),
                  ),
                  if (roomBed != null && roomBed.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _RoomBadge(roomBed: roomBed),
                  ],
                ],
              ),
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Lý do: $reason',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF424656),
                  ),
                ),
              ],
              if (actorName != null && actorName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Điều dưỡng: $actorName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF727687),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.roomBed});

  final String roomBed;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFA33200);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        roomBed,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyNotifications extends ConsumerWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(doctorNotificationsProvider);
        await ref.read(doctorNotificationsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Không có thông báo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191B24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thông báo khi điều dưỡng tạm dừng mức ăn sẽ hiển thị tại đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF727687),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
