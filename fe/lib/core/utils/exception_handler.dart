import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/failure.dart';

/// Maps raw exceptions to typed [AppException]
AppException mapException(Object error) {
  if (error is DioException) {
    return _mapDioException(error);
  }
  if (error is AppException) {
    return error;
  }
  return const UnknownException();
}

/// Maps [AppException] to [Failure] for domain layer
Failure mapExceptionToFailure(Object error) {
  final exception = mapException(error);
  return switch (exception) {
    NetworkException() => const NetworkFailure(),
    TimeoutException() => const NetworkFailure('Yêu cầu hết thời gian chờ'),
    UnauthorizedException() => const AuthFailure('Phiên đăng nhập hết hạn'),
    InvalidCredentialsException() => const InvalidCredentialsFailure(),
    AuthException() => AuthFailure(exception.message),
    ServerException(:final statusCode) => ServerFailure(
      statusCode: statusCode,
      message: exception.message,
    ),
    CacheException() => const CacheFailure(),
    _ => UnknownFailure(exception.message),
  };
}

AppException _mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badResponse => _mapStatusCode(e.response?.statusCode),
    _ => const UnknownException(),
  };
}

AppException _mapStatusCode(int? statusCode) {
  return switch (statusCode) {
    400 => const AuthException('Dữ liệu không hợp lệ'),
    401 => const UnauthorizedException(),
    403 => const ForbiddenException(),
    404 => const NotFoundException(),
    _ => ServerException(
      statusCode: statusCode ?? 500,
      message: 'Lỗi máy chủ ($statusCode)',
    ),
  };
}
