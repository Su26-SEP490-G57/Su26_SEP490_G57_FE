import 'package:dio/dio.dart';
import 'package:poms/main.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:poms/features/auth/domain/repositories/auth_repository.dart';
import 'package:poms/core/network/access_token_interceptor.dart';
import 'package:poms/core/network/refresh_token_interceptor.dart';
import 'package:poms/core/services/version_check_service.dart';

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
  final dio = Dio(
    BaseOptions(
      baseUrl: appFlavorConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: appFlavorConfig.apiConnectTimeout),
      receiveTimeout: Duration(milliseconds: appFlavorConfig.apiReceiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version-Code': appPackageInfo.buildNumber,
      },
    ),
  );

  // Reacts to a live 426 from the BE's min-app-version guard, on top of the
  // proactive version.json check — no AuthRepository dependency, so shared by
  // both createAuthDio() and createAppDio() (unlike AccessTokenInterceptor /
  // RefreshTokenInterceptor, which are app-dio-only to avoid a circular import).
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 426) {
          final body = error.response?.data;
          final message = body is Map ? body['message'] as String? : null;
          VersionCheckService.instance.reportForcedUpdate(message: message);
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
