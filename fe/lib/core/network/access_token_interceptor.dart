import 'package:dio/dio.dart';

/// Interceptor 1 — chỉ đọc access token từ memory và gán vào header.
/// Không bao giờ gọi network, không xử lý lỗi.
class AccessTokenInterceptor extends Interceptor {
  AccessTokenInterceptor(this._getAccessToken);

  /// Callback để lấy access token hiện tại từ memory (Riverpod / repository).
  /// Trả về null nếu chưa đăng nhập.
  final String? Function() _getAccessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
