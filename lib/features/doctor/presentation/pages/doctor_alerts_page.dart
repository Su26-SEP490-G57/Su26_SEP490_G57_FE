import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/doctor/presentation/providers/doctor_notification_provider.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';

/// Thông báo cho bác sĩ khi điều dưỡng hoàn thành xử trí một cảnh báo.
class DoctorAlertsPage extends ConsumerWidget {
  const DoctorAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The initial HTTP request remains the source of truth if the socket is
    // temporarily unavailable.
    ref.watch(doctorNotificationsRealtimeProvider);
    final notifications = ref.watch(doctorHandledAlertsProvider);

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
        error: (error, _) => _LoadError(
          onRetry: () => ref.invalidate(doctorHandledAlertsProvider),
        ),
        data: (alerts) {
          if (alerts.isEmpty) return const _EmptyNotifications();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(doctorHandledAlertsProvider);
              await ref.read(doctorHandledAlertsProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: alerts.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return const _NotificationsHeader();

                final alert = alerts[index - 1];
                return _HandledAlertCard(
                  alert: alert,
                  onTap: () => context.push(
                    AppRoutes.doctorPatientDetailPath(alert.caseId),
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
      padding: EdgeInsets.fromLTRB(4, 2, 4, 6),
      child: Text(
        'Cập nhật xử trí từ điều dưỡng',
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

class _HandledAlertCard extends StatelessWidget {
  const _HandledAlertCard({required this.alert, required this.onTap});

  final AlertModel alert;
  final VoidCallback onTap;

  Color get _severityColor => alert.alertType == 'RED'
      ? const Color(0xFFBA1A1A)
      : const Color(0xFFA33200);

  String get _severityLabel => alert.alertType == 'RED' ? 'MỨC ĐỎ' : 'MỨC VÀNG';

  String get _handledTime {
    final time = alert.handledAt ?? alert.triggeredAt;
    if (time == null) return 'Vừa cập nhật';
    return DateFormat('HH:mm · dd/MM/yyyy').format(time.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final action = alert.nurseAction?.trim();
    final note = alert.nursingNote?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Điều dưỡng đã hoàn thành xử trí',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191B24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SeverityBadge(label: _severityLabel, color: _severityColor),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Hồ sơ: ${alert.caseId}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424656),
                ),
              ),
              if (action != null && action.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailLine(label: 'Xử trí', content: action),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 6),
                _DetailLine(label: 'Ghi chú', content: note),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Color(0xFF727687),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _handledTime,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF727687),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF727687),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.content});

  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          height: 1.45,
          color: Color(0xFF424656),
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có thông báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF191B24),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các cập nhật khi điều dưỡng hoàn thành xử trí sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF727687),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFBA1A1A),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa thể tải thông báo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF191B24),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
