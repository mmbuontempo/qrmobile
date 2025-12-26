import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Servicio de almacenamiento seguro para tokens y datos sensibles
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey = 'device_id';
  static const _userKey = 'user_data';

  // Access Token
  static Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  static Future<void> setAccessToken(String token) => 
      _storage.write(key: _accessTokenKey, value: token);

  // Refresh Token
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  static Future<void> setRefreshToken(String token) => 
      _storage.write(key: _refreshTokenKey, value: token);

  // Device ID (persistente - NUNCA se borra)
  static Future<String> getDeviceId() async {
    var deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  // User data (cached)
  static Future<String?> getUserData() => _storage.read(key: _userKey);
  static Future<void> setUserData(String json) => 
      _storage.write(key: _userKey, value: json);

  // Limpiar todo (logout) - NO borra deviceId
  static Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
