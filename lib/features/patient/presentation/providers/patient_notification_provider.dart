import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/data/datasources/patient_notification_remote_datasource.dart';
import 'package:poms/features/patient/domain/models/patient_notification_model.dart';

// ── Infrastructure ───────────────────────────────────────────────────────────

final patientNotificationRemoteDataSourceProvider =
    Provider<PatientNotificationRemoteDataSource>((ref) {
      final dio = ref.watch(appDioProvider);
      return PatientNotificationRemoteDataSource(dio);
    });

// ── State ────────────────────────────────────────────────────────────────────

class PatientNotificationsState {
  const PatientNotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PatientNotificationModel> notifications;
  final bool isLoading;
  final String? errorMessage;

  PatientNotificationsState copyWith({
    List<PatientNotificationModel>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientNotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PatientNotificationsNotifier
    extends StateNotifier<PatientNotificationsState> {
  PatientNotificationsNotifier(this._dataSource)
    : super(const PatientNotificationsState()) {
    load();
  }

  final PatientNotificationRemoteDataSource _dataSource;

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications = await _dataSource.getMyNotifications();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, notifications: notifications);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Đánh dấu đã đọc: cập nhật UI ngay (optimistic), gọi API nền — không revert
  /// nếu lỗi vì đây chỉ là trạng thái hiển thị, không ảnh hưởng nghiệp vụ.
  Future<void> markAsRead(int notificationId) async {
    if (!mounted) return;
    final current = state.notifications;
    final alreadyRead = current
        .firstWhere((n) => n.notificationId == notificationId)
        .isRead;
    if (alreadyRead) return;

    state = state.copyWith(
      notifications: current
          .map(
            (n) => n.notificationId == notificationId
                ? n.copyWith(isRead: true)
                : n,
          )
          .toList(),
    );

    try {
      await _dataSource.markAsRead(notificationId);
    } catch (_) {
      // Best-effort — bỏ qua lỗi, lần load() kế tiếp sẽ tự đồng bộ lại.
    }
  }

  /// Chèn 1 thông báo vừa nhận qua socket (`notification.created`) lên đầu
  /// danh sách ngay khi app đang mở — không cần chờ FCM (không chạy trên
  /// simulator) hay phải mở lại màn để load() lại từ API.
  void upsertFromSocket(PatientNotificationModel notification) {
    if (!mounted) return;
    final alreadyExists = state.notifications.any(
      (n) => n.notificationId == notification.notificationId,
    );
    if (alreadyExists) return;
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
  }
}

final patientNotificationsNotifierProvider =
    StateNotifierProvider.autoDispose<
      PatientNotificationsNotifier,
      PatientNotificationsState
    >((ref) {
      final dataSource = ref.watch(patientNotificationRemoteDataSourceProvider);
      return PatientNotificationsNotifier(dataSource);
    });

/// Số thông báo chưa đọc — dùng để hiện chấm đỏ trên icon chuông ở trang chủ.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(patientNotificationsNotifierProvider);
  return state.notifications.where((n) => !n.isRead).length;
});
