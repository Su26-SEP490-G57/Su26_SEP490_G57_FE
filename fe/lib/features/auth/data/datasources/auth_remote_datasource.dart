import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/user_model.dart';
import 'prefs_interface.dart';

/// Handles Firebase Auth operations
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._firebaseAuth, this._prefs);

  final FirebaseAuth _firebaseAuth;
  final PrefsInterface _prefs;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
    String? forceRole, // dùng tạm khi chưa có custom claims / BE
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw const AuthException('Đăng nhập thất bại');

      // --- Role resolution ---
      // Priority 1: forceRole — truyền từ form khi biết chắc role (nurse form → 'nurse')
      // Priority 2: Firebase custom claims — khi BE sẵn sàng set claim
      // Priority 3: cached role từ session trước
      final idTokenResult = await user.getIdTokenResult();
      final claimRole = idTokenResult.claims?['role'] as String?;
      final cachedRole = await _prefs.getString(AppConstants.keyUserRole);

      final roleStr = forceRole ?? claimRole ?? cachedRole;
      if (roleStr == null) {
        throw const AuthException(
          'Tài khoản chưa được gán vai trò. Liên hệ quản trị viên.',
        );
      }

      final role = _parseRole(roleStr);

      // Persist role và rememberMe
      await _prefs.setString(AppConstants.keyUserRole, role.name);
      await _prefs.setBool(AppConstants.keyRememberMe, rememberMe);

      return UserModel(
        uid: user.uid,
        email: user.email ?? email,
        role: role,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException {
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _prefs.remove(AppConstants.keyUserRole);
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  Future<bool> getRememberMe() async {
    return await _prefs.getBool(AppConstants.keyRememberMe) ?? false;
  }

  /// Throws [AuthException] nếu roleStr không hợp lệ
  UserRole _parseRole(String roleStr) {
    try {
      return UserRoleX.fromString(roleStr);
    } catch (_) {
      throw AuthException('Vai trò không hợp lệ: "$roleStr"');
    }
  }
}
