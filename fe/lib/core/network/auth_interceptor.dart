import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Automatically attaches Firebase ID token to every request.
/// On 401 response: refreshes token once and retries.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        options.headers['Authorization'] = 'Bearer $token';
      } catch (_) {
        // If token fetch fails, proceed without token — server will return 401
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh once
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken(true); // force refresh
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';

          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh failed — sign out and let the app handle redirect
        await FirebaseAuth.instance.signOut();
      }
    }
    handler.next(err);
  }
}
