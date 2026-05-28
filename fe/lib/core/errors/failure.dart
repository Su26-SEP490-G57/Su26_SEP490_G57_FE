import 'package:equatable/equatable.dart';

/// Failure — used in domain layer to represent errors
/// without leaking infrastructure details
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Lỗi kết nối mạng']);
}

final class ServerFailure extends Failure {
  const ServerFailure({
    required this.statusCode,
    String message = 'Lỗi máy chủ',
  }) : super(message);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Lỗi xác thực']);
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Email hoặc mật khẩu không đúng',
  ]);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi lưu trữ cục bộ']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Đã xảy ra lỗi không xác định']);
}
