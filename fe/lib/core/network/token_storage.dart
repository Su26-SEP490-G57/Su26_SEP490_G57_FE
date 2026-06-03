import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Wrapper quanh [FlutterSecureStorage] — chỉ xử lý refresh token.
/// Access token KHÔNG được lưu vào đây — chỉ tồn tại in-memory (Riverpod).
class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  // ── Refresh token ────────────────────────────────────────────────────────

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.keyRefreshToken, value: token);

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: AppConstants.keyRefreshToken);

  // ── Clear all ────────────────────────────────────────────────────────────

  Future<void> clearAll() => _storage.deleteAll();
}
