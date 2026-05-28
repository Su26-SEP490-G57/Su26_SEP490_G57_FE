/// Base exception class for POMS app
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Network / HTTP errors
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Lỗi kết nối mạng']);
}

final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Yêu cầu hết thời gian chờ']);
}

final class ServerException extends AppException {
  const ServerException({
    required this.statusCode,
    String message = 'Lỗi máy chủ',
  }) : super(message);

  final int statusCode;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Phiên đăng nhập hết hạn']);
}

final class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Không có quyền truy cập']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Không tìm thấy dữ liệu']);
}

/// Auth errors
final class AuthException extends AppException {
  const AuthException([super.message = 'Lỗi xác thực']);
}

final class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([
    super.message = 'Email hoặc mật khẩu không đúng',
  ]);
}

/// Cache / local storage errors
final class CacheException extends AppException {
  const CacheException([super.message = 'Lỗi lưu trữ cục bộ']);
}

/// Unknown / unexpected errors
final class UnknownException extends AppException {
  const UnknownException([super.message = 'Đã xảy ra lỗi không xác định']);
}
