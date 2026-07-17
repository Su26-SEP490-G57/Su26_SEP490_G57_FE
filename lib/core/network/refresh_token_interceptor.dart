import 'dart:async';

import 'package:dio/dio.dart';

import 'package:poms/features/auth/domain/repositories/auth_repository.dart';

/// Interceptor 2 — xử lý 401 Unauthorized.
///
/// Khi nhận 401:
///   1. Acquire lock (chỉ 1 request được gọi refresh tại 1 thời điểm)
///   2. Gọi [AuthRepository.refreshAccessToken]
///   3. Retry original request với access token mới
///   4. Nếu refresh thất bại → propagate lỗi (GoRouter sẽ redirect về /login
///      vì authStateChanges phát null từ AuthRepositoryImpl)
///
/// Các request khác cùng nhận 401 trong lúc đang refresh sẽ queue chờ
/// kết quả từ lock → tránh gọi refresh N lần đồng thời.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required Dio dio,
    required AuthRepository authRepository,
  }) : _dio = dio,
       _authRepository = authRepository;

  /// Dio instance CHÍNH — dùng để retry original request.
  final Dio _dio;
  final AuthRepository _authRepository;

  // Lock mechanism: chỉ 1 coroutine được refresh tại 1 thời điểm
  bool _isRefreshing = false;
  final List<_PendingRequest> _queue = [];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Tránh infinite loop: nếu chính request refresh bị 401
    final isRefreshEndpoint = err.requestOptions.path.contains('/auth/refresh');
    if (isRefreshEndpoint) {
      return handler.next(err);
    }

    final originalRequest = err.requestOptions;

    if (_isRefreshing) {
      // Queue lại, chờ refresh hoàn thành
      final completer = Completer<Response<dynamic>>();
      _queue.add(
        _PendingRequest(request: originalRequest, completer: completer),
      );
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      // Lấy access token mới
      final newToken = await _authRepository.refreshAccessToken();

      // Retry original request
      final response = await _retryRequest(originalRequest, newToken);

      // Giải phóng queue — tất cả request đang chờ retry với token mới
      _resolveQueue(newToken);

      return handler.resolve(response);
    } catch (e) {
      // Refresh thất bại — reject tất cả request đang queue
      _rejectQueue(e);
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Response<dynamic>> _retryRequest(
    RequestOptions options,
    String newToken,
  ) {
    options.headers['Authorization'] = 'Bearer $newToken';
    return _dio.fetch(options);
  }

  void _resolveQueue(String newToken) {
    final pending = List<_PendingRequest>.from(_queue);
    _queue.clear();
    for (final item in pending) {
      _retryRequest(
        item.request,
        newToken,
      ).then(item.completer.complete).catchError(item.completer.completeError);
    }
  }

  void _rejectQueue(Object error) {
    final pending = List<_PendingRequest>.from(_queue);
    _queue.clear();
    for (final item in pending) {
      item.completer.completeError(error);
    }
  }
}

// ── Internal ─────────────────────────────────────────────────────────────────

class _PendingRequest {
  const _PendingRequest({required this.request, required this.completer});
  final RequestOptions request;
  final Completer<Response<dynamic>> completer;
}
