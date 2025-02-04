import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._sharedInstance();
  static final SecureStorage _shared = SecureStorage._sharedInstance();
  factory SecureStorage() => _shared;

  final secureStorage = FlutterSecureStorage();

  final _accessTokenKey = 'ermis_stream_access_token';

  Future<String?> get accessToken async {
    return await secureStorage.read(key: _accessTokenKey);
  }

  Future<void> setAccessToken(String? accessToken) async {
    if (accessToken != null) {
      await secureStorage.write(key: _accessTokenKey, value: accessToken);
    } else {
      await secureStorage.delete(key: _accessTokenKey);
    }
  }

  Future<void>reset() async {
    await secureStorage.deleteAll();
  }
}