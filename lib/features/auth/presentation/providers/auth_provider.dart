import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poms/core/network/dio_client.dart';
import 'package:poms/core/network/token_storage.dart';
import 'package:poms/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:poms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';
import 'package:poms/features/auth/domain/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return const TokenStorage(secureStorage);
});

// ---------------------------------------------------------------------------
// Dio providers
//
// authDioProvider  — không có interceptor, dùng cho /auth/* endpoints
// appDioProvider   — có 2 interceptors, dùng cho mọi API call khác
//
// Thứ tự khởi tạo:
//   authDioProvider (không dependency)
//   → authRepositoryProvider (dùng authDio)
//   → appDioProvider (inject authRepository)
// ---------------------------------------------------------------------------

/// Dio dùng cho auth endpoints — KHÔNG có auth interceptor
final authDioProvider = Provider<Dio>((ref) {
  return createAuthDio();
});

/// Repository cần được tạo TRƯỚC appDio để inject vào RefreshTokenInterceptor
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authDio = ref.watch(authDioProvider);
  final dataSource = AuthRemoteDataSource(authDio);

  final repo = AuthRepositoryImpl(
    dataSource: dataSource,
    prefs: prefs,
    tokenStorage: tokenStorage,
  );

  ref.onDispose(repo.dispose);

  return repo;
});

/// Dio dùng cho tất cả API calls — CÓ 2 interceptors
final appDioProvider = Provider<Dio>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return createAppDio(authRepository: authRepository);
});

// ---------------------------------------------------------------------------
// Auth state stream — drives GoRouter redirect
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Auth notifier — login / logout actions
// ---------------------------------------------------------------------------

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.justLoggedIn = false,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  /// true chỉ ngay sau khi signIn thành công — dashboard đọc xong phải clear
  final bool justLoggedIn;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? justLoggedIn,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      justLoggedIn: justLoggedIn ?? this.justLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> signIn({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signIn(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        justLoggedIn: true,
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Xóa flag justLoggedIn sau khi dashboard đã hiển thị toast
  void clearLoginToast() {
    if (state.justLoggedIn) {
      state = state.copyWith(justLoggedIn: false);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
