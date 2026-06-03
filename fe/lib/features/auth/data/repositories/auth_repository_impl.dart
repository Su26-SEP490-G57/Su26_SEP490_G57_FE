import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/utils/exception_handler.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource dataSource,
    required SharedPreferences prefs,
    required TokenStorage tokenStorage,
  }) : _dataSource = dataSource,
       _prefs = prefs,
       _tokenStorage = tokenStorage {
    _readyCompleter = Completer<void>();
    _initSession().then((_) => _readyCompleter.complete()).catchError((e) {
      _readyCompleter.completeError(e);
    });
  }

  final AuthRemoteDataSource _dataSource;
  final SharedPreferences _prefs;
  final TokenStorage _tokenStorage;

  /// Access token — in-memory only, never persisted
  String? _accessToken;

  /// Cached user — updated on login/logout/restore
  UserModel? _currentUserCache;

  /// Completes when _initSession() finishes — gates authStateChanges
  late final Completer<void> _readyCompleter;

  final _authStateController = StreamController<UserModel?>.broadcast();

  // ── AuthRepository interface ─────────────────────────────────────────────

  /// Stream luôn emit giá trị hiện tại ngay khi subscriber đăng ký,
  /// rồi tiếp tục emit các thay đổi tiếp theo.
  ///
  /// Sau khi _initSession hoàn thành, seed _currentUserCache rồi
  /// tiếp tục lắng nghe _authStateController cho các updates.
  @override
  Stream<UserModel?> get authStateChanges async* {
    // Chờ init session xong
    await _readyCompleter.future;
    // Emit giá trị hiện tại ngay
    yield _currentUserCache;
    // Tiếp tục emit mọi thay đổi sau đó
    yield* _authStateController.stream;
  }

  @override
  UserModel? get currentUser => _currentUserCache;

  @override
  String? getAccessToken() => _accessToken;

  @override
  bool get isRememberMeEnabled =>
      _prefs.getBool(AppConstants.keyRememberMe) ?? false;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final result = await _dataSource.login(email: email, password: password);

      _accessToken = result.accessToken;

      await _tokenStorage.saveRefreshToken(result.refreshToken);
      await _saveUserToPrefs(result.user);
      await _prefs.setBool(AppConstants.keyRememberMe, rememberMe);

      _currentUserCache = result.user;
      _authStateController.add(result.user);

      return result.user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    await _dataSource.logout(refreshToken);
    await _clearSession();
    _currentUserCache = null;
    _authStateController.add(null);
  }

  @override
  Future<String> refreshAccessToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        throw const UnauthorizedException('Không có refresh token');
      }
      final newAccessToken = await _dataSource.refreshAccessToken(refreshToken);
      _accessToken = newAccessToken;
      return newAccessToken;
    } on UnauthorizedException {
      await _clearSession();
      _currentUserCache = null;
      _authStateController.add(null);
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapException(e);
    }
  }

  // ── Session init ─────────────────────────────────────────────────────────

  /// Chạy 1 lần khi constructor. Kết quả gate authStateChanges qua Completer.
  ///
  /// rememberMe = false → xóa mọi token & profile, cache null
  /// rememberMe = true  → restore user từ SharedPreferences, cache user
  ///   (access token = null; refresh token còn trong SecureStorage
  ///    → RefreshTokenInterceptor tự lấy token mới ở request đầu tiên)
  Future<void> _initSession() async {
    final rememberMe = _prefs.getBool(AppConstants.keyRememberMe) ?? false;

    if (!rememberMe) {
      await _clearSession();
      _currentUserCache = null;
    } else {
      _currentUserCache = _loadUserFromPrefs();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _saveUserToPrefs(UserModel user) async {
    await _prefs.setString(
      AppConstants.keyUserProfile,
      jsonEncode(user.toJson()),
    );
  }

  UserModel? _loadUserFromPrefs() {
    final json = _prefs.getString(AppConstants.keyUserProfile);
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    await _tokenStorage.deleteRefreshToken();
    await _prefs.remove(AppConstants.keyUserProfile);
    await _prefs.remove(AppConstants.keyRememberMe);
    await _prefs.remove(AppConstants.keyUserRole);
  }

  void dispose() {
    _authStateController.close();
  }
}
