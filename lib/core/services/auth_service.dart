import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'google_auth_service.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

/// Servicio principal de autenticación
class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  
  final GoogleAuthService _googleAuth = GoogleAuthService();

  /// Obtener info del dispositivo
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await SecureStorageService.getDeviceId();
    
    String deviceName = 'Mobile App';
    String deviceOS = 'Unknown';
    
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        deviceName = '${android.brand} ${android.model}';
        deviceOS = 'Android ${android.version.release}';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        deviceName = ios.name;
        deviceOS = '${ios.systemName} ${ios.systemVersion}';
      }
    } catch (_) {}
    
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceOS': deviceOS,
      'appVersion': packageInfo.version,
    };
  }

  /// Intercambiar código de autorización por tokens
  Future<UserModel?> exchangeAuthCode(String code) async {
    // 1. Obtener info del dispositivo
    final deviceInfo = await _getDeviceInfo();

    try {
      // 2. Enviar al backend
      final response = await _dio.post(AppConstants.mobileAuthToken, data: {
        'code': code,
        ...deviceInfo,
      });

      final data = response.data;

      // 3. Guardar tokens
      await SecureStorageService.setAccessToken(data['accessToken']);
      await SecureStorageService.setRefreshToken(data['refreshToken']);
      
      // 4. Guardar datos del usuario
      final user = UserModel.fromJson(data['user']);
      await SecureStorageService.setUserData(jsonEncode(data['user']));

      debugPrint('[Auth] Login con código exitoso: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('[Auth] Error intercambiando código: $e');
      return null;
    }
  }

  /// LOGIN CON GOOGLE - Método principal
  /// Retorna el usuario autenticado o null si canceló
  Future<UserModel?> signInWithGoogle() async {
    // 1. Obtener idToken de Google
    final idToken = await _googleAuth.signIn();
    
    if (idToken == null) {
      return null;
    }

    // 2. Obtener info del dispositivo
    final deviceInfo = await _getDeviceInfo();

    // 3. Enviar al backend
    final response = await _dio.post(AppConstants.mobileAuthGoogle, data: {
      'idToken': idToken,
      ...deviceInfo,
    });

    final data = response.data;

    // 4. Guardar tokens
    await SecureStorageService.setAccessToken(data['accessToken']);
    await SecureStorageService.setRefreshToken(data['refreshToken']);
    
    // 5. Guardar datos del usuario
    final user = UserModel.fromJson(data['user']);
    await SecureStorageService.setUserData(jsonEncode(data['user']));

    debugPrint('[Auth] Login exitoso: ${user.email}');
    return user;
  }

  /// Renovar tokens usando refresh token
  Future<bool> refreshTokens() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    final deviceId = await SecureStorageService.getDeviceId();
    
    if (refreshToken == null) return false;
    
    try {
      final response = await _dio.post(AppConstants.mobileAuthRefresh, data: {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      });
      
      final data = response.data;
      
      await SecureStorageService.setAccessToken(data['accessToken']);
      await SecureStorageService.setRefreshToken(data['refreshToken']);
      
      debugPrint('[Auth] Tokens renovados');
      return true;
    } catch (e) {
      debugPrint('[Auth] Error renovando tokens: $e');
      await SecureStorageService.clearAll();
      return false;
    }
  }

  /// Obtener usuario actual desde el servidor
  Future<UserModel?> getCurrentUser() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        AppConstants.mobileAuthMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      debugPrint('[Auth] Error obteniendo usuario: $e');
      return null;
    }
  }

  /// Obtener usuario cacheado (sin request)
  Future<UserModel?> getCachedUser() async {
    final userData = await SecureStorageService.getUserData();
    if (userData == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userData));
    } catch (_) {
      return null;
    }
  }

  /// Logout completo
  Future<void> logout() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    
    // Revocar token en el servidor
    if (refreshToken != null) {
      try {
        await _dio.post(AppConstants.mobileAuthLogout, data: {
          'refreshToken': refreshToken,
        });
      } catch (_) {}
    }
    
    // Cerrar sesión de Google
    await _googleAuth.signOut();
    
    // Limpiar almacenamiento local
    await SecureStorageService.clearAll();
    
    debugPrint('[Auth] Logout completado');
  }

  /// Verificar si hay sesión activa
  Future<bool> isAuthenticated() async {
    return await SecureStorageService.isAuthenticated();
  }

  // ===========================================================================
  // DISPOSITIVOS Y SEGURIDAD (Audit 2.1)
  // ===========================================================================

  /// Listar dispositivos activos
  Future<List<Map<String, dynamic>>> getDevices() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/mobile/auth/devices',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('[Auth] Error obteniendo dispositivos: $e');
      return [];
    }
  }

  /// Revocar sesión de un dispositivo específico
  Future<bool> revokeDevice(String deviceId) async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null) return false;

    try {
      await _dio.delete(
        '${AppConstants.apiBaseUrl}/api/mobile/auth/devices/$deviceId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      debugPrint('[Auth] Error revocando dispositivo: $e');
      return false;
    }
  }

  /// Cerrar todas las sesiones (excepto la actual si se maneja en UI)
  /// Nota: El endpoint /logout-all revoca TODO, incluyendo el token actual.
  Future<bool> logoutAllDevices() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null) return false;

    try {
      await _dio.post(
        '${AppConstants.apiBaseUrl}/api/mobile/auth/logout-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Limpiamos localmente también
      await logout();
      return true;
    } catch (e) {
      debugPrint('[Auth] Error en logout global: $e');
      return false;
    }
  }
}
