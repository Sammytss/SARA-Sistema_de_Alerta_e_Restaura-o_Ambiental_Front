import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper seguro para tokens JWT e dados de sessão.
/// Usa Keystore (Android) / Keychain (iOS) via flutter_secure_storage.
/// NUNCA armazenar tokens em shared_preferences ou similar.
class SecureStore {
  static const _accessTokenKey = 'sara_access_token';
  static const _refreshTokenKey = 'sara_refresh_token';
  static const _userJsonKey = 'sara_user_json';

  final FlutterSecureStorage _storage;

  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<Map<String, dynamic>?> getUserJson() async {
    final raw = await _storage.read(key: _userJsonKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setUserJson(Map<String, dynamic> user) =>
      _storage.write(key: _userJsonKey, value: jsonEncode(user));

  Future<bool> hasSession() async =>
      (await getAccessToken()) != null;

  Future<void> clearAll() => _storage.deleteAll();
}
