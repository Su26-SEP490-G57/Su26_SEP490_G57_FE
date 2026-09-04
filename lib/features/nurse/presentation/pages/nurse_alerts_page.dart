import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/nurse/domain/models/alert_model.dart';
import 'package:poms/features/nurse/presentation/providers/alert_provider.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';

class NurseAlertsPage extends ConsumerWidget {
  const NurseAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(alertRealtimeProvider);

    final alertsState = ref.watch(alertsNotifierProvider);
    // Chi hien thi cac canh bao dang pending, cu nhat (overdue) len dau.
    final alerts = ref.watch(pendingAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cảnh báo Y tế',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(alertsNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: _buildBody(context, ref, alertsState, alerts),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AlertsState alertsState,
    List<AlertModel> alerts,
  ) {
    if (alertsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (alertsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải dữ liệu:\n${alertsState.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.read(alertsNotifierProvider.notifier).load(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có cảnh báo nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tất cả bệnh nhân đang ổn định.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurface.withValues(alpha: 0.6),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(alertsNotifierProvider.notifier).load(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        itemCount: alerts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _AlertCard(alert: alerts[index]),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Alert Card — thiet ke nho gon, toi uu dien tich, hien thi truc tiep gia tri
// -----------------------------------------------------------------------------

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});

  final AlertModel alert;

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa ghi nhận';
    final vnTime = dateTime.toUtc().add(const Duration(hours: 7));
    return DateFormat('HH:mm • dd/MM/yyyy').format(vnTime);
  }

  String _formatRoom(String? rawRoom) {
    if (rawRoom == null || rawRoom.isEmpty) return 'Chưa xếp phòng';
    return rawRoom.replaceAll('Buồng ', 'P.').replaceAll('Giường ', 'G.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRed = alert.alertType.toUpperCase() == 'RED';

    final cardBg = isRed ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isRed
        ? const Color(0xFFFCA5A5)
        : const Color(0xFFFDE68A);
    final accentColor = isRed
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final iconBg = isRed ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final chipBg = isRed ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);

    final patient = ref.watch(patientByIdProvider(alert.caseId));
    final displayName = patient?.name ?? alert.caseId;
    final roomLocation = _formatRoom(patient?.room);
    final operationType =
        (patient?.operationTypeName != null &&
            patient!.operationTypeName!.isNotEmpty)
        ? patient.operationTypeName!
        : ((patient?.surgeryType != null && patient!.surgeryType!.isNotEmpty)
              ? patient.surgeryType!
              : 'Chưa cập nhật');
    final dietLevelStr = 'Mức ${patient?.dietLevel ?? 0}';
    final triggeredTimeStr = _formatTime(alert.triggeredAt);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.nursePatientDetailPath(alert.caseId)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon Circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                isRed ? Icons.emergency_rounded : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Middle Main Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Patient Name & Room Location Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              roomLocation,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Line 2: Surgery Type
                  Text(
                    operationType,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Line 3: Diet Level & Triggered Time
                  Row(
                    children: [
                      // Diet level chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.restaurant_outlined,
                              size: 11,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              dietLevelStr,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Triggered Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            triggeredTimeStr,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Right Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
