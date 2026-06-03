import '../models/user_model.dart';

abstract interface class AuthRepository {
  /// Stream phát ra user hiện tại.
  /// Emit [UserModel] khi authenticated, null khi signed out.
  /// Dùng bởi GoRouter để redirect.
  Stream<UserModel?> get authStateChanges;

  /// User hiện tại (synchronous, từ memory).
  UserModel? get currentUser;

  /// Đăng nhập bằng email/password.
  /// Lưu access token vào memory, refresh token vào SecureStorage,
  /// user profile vào memory + SharedPreferences.
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Đăng xuất — xóa tất cả tokens và profile khỏi mọi storage.
  Future<void> signOut();

  /// Lấy access token hiện tại từ memory (null nếu chưa login).
  String? getAccessToken();

  /// Dùng refresh token để lấy access token mới.
  /// Throw [UnauthorizedException] nếu refresh token hết hạn.
  Future<String> refreshAccessToken();

  /// Whether "remember me" was checked on last login.
  bool get isRememberMeEnabled;
}
