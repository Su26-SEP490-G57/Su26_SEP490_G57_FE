import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../constants/app_constants.dart';
import 'access_token_interceptor.dart';
import 'refresh_token_interceptor.dart';

// ---------------------------------------------------------------------------
// Auth Dio — không có interceptor, chỉ dùng cho /auth/login & /auth/refresh
// Tránh circular dependency: AuthRemoteDataSource dùng Dio này, không phải
// Dio đã gắn RefreshTokenInterceptor.
// ---------------------------------------------------------------------------

Dio createAuthDio() => _buildBaseDio();

// ---------------------------------------------------------------------------
// App Dio — gắn 2 interceptors, dùng cho tất cả API calls khác
//
// [authRepository] được inject từ bên ngoài (auth_provider.dart) để tránh
// circular import giữa dio_client ↔ auth_provider.
// ---------------------------------------------------------------------------

Dio createAppDio({required AuthRepository authRepository}) {
  final dio = _buildBaseDio();

  // Interceptor 1: đọc access token từ memory, gán vào header
  dio.interceptors.add(
    AccessTokenInterceptor(() => authRepository.getAccessToken()),
  );

  // Interceptor 2: refresh token khi 401, retry original request
  dio.interceptors.add(
    RefreshTokenInterceptor(dio: dio, authRepository: authRepository),
  );

  // Logger — debug only
  assert(() {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
    return true;
  }());

  return dio;
}

// ---------------------------------------------------------------------------
// Shared base config
// ---------------------------------------------------------------------------

Dio _buildBaseDio() {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
