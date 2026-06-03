import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/user_model.dart';

/// Gọi REST API cho các auth operations.
/// Không có dependency vào Firebase.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  /// Dio instance KHÔNG có auth interceptor — dùng riêng cho login & refresh
  /// để tránh circular dependency.
  final Dio _dio;

  /// POST /auth/login
  /// Response shape mong đợi từ BE:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "accessToken": "...",
  ///     "refreshToken": "...",
  ///     "user": { "uid": "...", "email": "...", "role": "nurse", "displayName": "..." }
  ///   }
  /// }
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConstants.endpointLogin,
        data: {'email': email, 'password': password},
      );

      final body = response.data;
      if (body == null) throw const AuthException('Phản hồi không hợp lệ');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) throw const AuthException('Phản hồi không hợp lệ');

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (accessToken == null || refreshToken == null || userJson == null) {
        throw const AuthException('Thiếu dữ liệu trong phản hồi');
      }

      return LoginResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserModel.fromJson(userJson),
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /auth/refresh
  /// Body: { "refreshToken": "..." }
  /// Response shape:
  /// { "success": true, "data": { "accessToken": "..." } }
  Future<String> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConstants.endpointRefresh,
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      final data = body?['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['accessToken'] as String?;

      if (newAccessToken == null) {
        throw const AuthException('Không nhận được access token mới');
      }

      return newAccessToken;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /auth/logout — thông báo BE invalidate refresh token
  /// Fire-and-forget: không throw nếu thất bại
  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null) return;
    try {
      await _dio.post<void>(
        AppConstants.endpointLogout,
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Ignore — local cleanup vẫn diễn ra bất kể BE có phản hồi hay không
    }
  }

  // ── Error mapping ────────────────────────────────────────────────────────

  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final responseData = e.response?.data;
    final dataMap = responseData is Map<String, dynamic> ? responseData : null;
    final message =
        dataMap?['message'] as String? ?? dataMap?['error'] as String?;

    // Network/timeout errors (no response)
    if (e.response == null) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const TimeoutException();
      }
      throw const NetworkException();
    }

    switch (statusCode) {
      case 400:
        throw AuthException(message ?? 'Dữ liệu không hợp lệ');
      case 401:
        throw const InvalidCredentialsException();
      case 403:
        throw const ForbiddenException();
      case 404:
        throw const NotFoundException();
      case >= 500:
        throw ServerException(
          statusCode: statusCode,
          message: message ?? 'Lỗi máy chủ',
        );
      default:
        throw NetworkException(message ?? 'Lỗi không xác định ($statusCode)');
    }
  }
}

// ── Result types ─────────────────────────────────────────────────────────────

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;
}
