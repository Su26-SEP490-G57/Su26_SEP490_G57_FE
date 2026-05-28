import '../models/user_model.dart';

abstract interface class AuthRepository {
  /// Stream of current user — emits null when signed out
  Stream<UserModel?> get authStateChanges;

  /// Current user synchronously (null if not signed in)
  UserModel? get currentUser;

  /// Nurse: sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
    String? forceRole,
  });

  /// Sign out
  Future<void> signOut();

  /// Get fresh Firebase ID token for API calls
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Whether "remember me" was checked on last login
  bool get isRememberMeEnabled;
}
