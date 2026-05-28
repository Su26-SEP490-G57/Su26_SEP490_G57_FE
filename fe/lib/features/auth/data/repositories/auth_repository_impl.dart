import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/exception_handler.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._prefs);

  final AuthRemoteDataSource _dataSource;
  final SharedPreferences _prefs;

  @override
  Stream<UserModel?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _buildUserModel(firebaseUser);
    });
  }

  @override
  UserModel? get currentUser {
    final firebaseUser = _dataSource.currentFirebaseUser;
    if (firebaseUser == null) return null;

    final roleStr = _prefs.getString(AppConstants.keyUserRole);
    UserRole role;
    try {
      role = roleStr != null ? UserRoleX.fromString(roleStr) : UserRole.nurse;
    } catch (_) {
      role = UserRole.nurse;
    }

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      role: role,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }

  @override
  bool get isRememberMeEnabled =>
      _prefs.getBool(AppConstants.keyRememberMe) ?? false;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
    String? forceRole,
  }) async {
    try {
      return await _dataSource.signIn(
        email: email,
        password: password,
        rememberMe: rememberMe,
        forceRole: forceRole,
      );
    } on FirebaseAuthException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) {
    return _dataSource.getIdToken(forceRefresh: forceRefresh);
  }

  Future<UserModel> _buildUserModel(User firebaseUser) async {
    final roleStr = _prefs.getString(AppConstants.keyUserRole);
    UserRole role;
    try {
      role = roleStr != null ? UserRoleX.fromString(roleStr) : UserRole.nurse;
    } catch (_) {
      role = UserRole.nurse;
    }

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      role: role,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }
}
