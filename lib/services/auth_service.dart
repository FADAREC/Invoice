import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      // On error, assume not authenticated
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveToken(String token, String userId) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      print('⚠️ Could not save auth token: $e');
      rethrow; // Let caller handle this
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
    } catch (e) {
      print('⚠️ Logout error, clearing all storage: $e');
      await _storage.deleteAll();
    }
  }
}