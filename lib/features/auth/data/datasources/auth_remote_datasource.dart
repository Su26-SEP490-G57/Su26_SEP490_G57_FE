import 'package:dio/dio.dart';

import 'package:poms/core/constants/app_constants.dart';
import 'package:poms/core/errors/app_exception.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConstants.endpointLogin,
        data: {'username': username, 'password': password},
      );

      final body = response.data;

      if (body == null) {
        throw const AuthException('Response body is null');
      }

      // Backend trả thẳng:
      // {
      //   accessToken,
      //   refreshToken,
      //   user
      // }

      final accessToken = body['accessToken'] as String?;
      final refreshToken = body['refreshToken'] as String?;
      final userJson = body['user'] as Map<String, dynamic>?;

      if (accessToken == null) {
        throw const AuthException('Missing accessToken');
      }

      if (refreshToken == null) {
        throw const AuthException('Missing refreshToken');
      }

      if (userJson == null) {
        throw const AuthException('Missing user object');
      }

      return LoginResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserModel.fromJson(userJson),
      );
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    throw const UnauthorizedException(
      'Refresh token endpoint is not implemented',
    );
  }

  Future<void> logout(String? refreshToken) async {
    return;
  }

  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final responseData = e.response?.data;
    final dataMap = responseData is Map<String, dynamic> ? responseData : null;

    final message =
        dataMap?['message'] as String? ?? dataMap?['error'] as String?;

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
        throw AuthException(message ?? 'Bad request');

      case 401:
        throw const InvalidCredentialsException();

      case 403:
        throw const ForbiddenException();

      case 404:
        throw const NotFoundException();

      default:
        if (statusCode >= 500) {
          throw ServerException(
            statusCode: statusCode,
            message: message ?? 'Server error',
          );
        }

        throw NetworkException(message ?? 'Unknown error ($statusCode)');
    }
  }
}

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
