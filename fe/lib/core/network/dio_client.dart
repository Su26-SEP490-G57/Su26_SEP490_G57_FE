import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

/// Creates and configures the singleton Dio instance
Dio createDioClient() {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api';

  final dio = Dio(
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

  // Auth interceptor — attaches Firebase ID token
  dio.interceptors.add(AuthInterceptor(dio));

  // Logger — only in debug mode
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
