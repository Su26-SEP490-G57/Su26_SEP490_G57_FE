import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/prefs_interface.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataSource = AuthRemoteDataSource(
    firebaseAuth,
    _SharedPrefsAdapter(prefs),
  );
  return AuthRepositoryImpl(dataSource, prefs);
});

// ---------------------------------------------------------------------------
// Auth state stream — drives GoRouter redirect
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
    String? forceRole,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
        rememberMe: rememberMe,
        forceRole: forceRole,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// ---------------------------------------------------------------------------
// SharedPreferences adapter
// ---------------------------------------------------------------------------

class _SharedPrefsAdapter implements PrefsInterface {
  _SharedPrefsAdapter(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      _prefs.setString(key, value);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async =>
      _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);
}
