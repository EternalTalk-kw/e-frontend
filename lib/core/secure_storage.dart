import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyAccess = 'access_token';

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccess, value: token);

  static Future<String?> readAccessToken() =>
      _storage.read(key: _keyAccess);

  static Future<void> clear() => _storage.deleteAll();
}
