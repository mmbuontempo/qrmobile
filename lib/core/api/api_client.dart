import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';

/// API Client con auto-refresh de tokens JWT
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final AuthService _authService = AuthService();

  // Callback cuando la sesión expira completamente
  static Function()? onSessionExpired;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Agregar token JWT a todas las requests
        final token = await SecureStorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('[API] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        debugPrint('[API Error] ${error.response?.statusCode} ${error.message}');
        
        // Si es 401, intentar refresh automático
        if (error.response?.statusCode == 401) {
          final refreshed = await _authService.refreshTokens();
          
          if (refreshed) {
            // Reintentar con nuevo token
            final token = await SecureStorageService.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            // Sesión expirada completamente
            onSessionExpired?.call();
          }
        }
        return handler.next(error);
      },
    ));
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  // QR endpoints
  Future<Response> getQrList() => _dio.get('/api/qr');
  
  Future<Response> createQr(Map<String, dynamic> data) => 
      _dio.post('/api/qr', data: data);
  
  Future<Response> getQr(String id) => _dio.get('/api/qr/$id');

  Future<Response> updateQr(String id, Map<String, dynamic> data) => 
      _dio.patch('/api/qr/$id', data: data);
  
  Future<Response> deleteQr(String id) => 
      _dio.delete('/api/qr/$id');

  Future<Response> toggleQr(String id) => 
      _dio.post('/api/qr/$id/toggle');

  Future<Response> duplicateQr(String id) => 
      _dio.post('/api/qr/$id/duplicate');

  Future<Response> getQrRules(String id) => 
      _dio.get('/api/qr/$id/rules');

  Future<Response> updateQrRules(String id, Map<String, dynamic> data) => 
      _dio.put('/api/qr/$id/rules', data: data);

  Future<Response> getQrAnalytics(String id) => 
      _dio.get('/api/qr/$id/analytics');

  Future<Response> getQrReport(String id) => 
      _dio.get('/api/qr/$id/report');

  // General Analytics (Markov/Montecarlo)
  Future<Response> getGeneralAnalytics() => _dio.get('/api/analytics');

  // Stats
  Future<Response> getDashboardStats() => _dio.get('/api/stats');

  // Folders
  Future<Response> getFolders() => _dio.get('/api/folders');
  
  Future<Response> createFolder(Map<String, dynamic> data) => 
      _dio.post('/api/folders', data: data);

  Future<Response> updateFolder(String id, Map<String, dynamic> data) => 
      _dio.patch('/api/folders/$id', data: data);

  Future<Response> deleteFolder(String id) => 
      _dio.delete('/api/folders/$id');

  // Billing
  Future<Response> getBillingStatus() => _dio.get('/api/billing/status');
  
  Future<Response> createPaymentIntent(Map<String, dynamic> data) => 
      _dio.post('/api/billing/create-intent', data: data);

  // Account
  Future<Response> updateProfile(Map<String, dynamic> data) => 
      _dio.patch('/api/account/profile', data: data);

  Future<Response> getSubscription() => 
      _dio.get('/api/account/subscription');

  Future<Response> deleteAccount() => 
      _dio.delete('/api/account/delete');

  Future<Response> acceptTerms() => 
      _dio.post('/api/account/accept-terms');

  // Auth Extras (Devices)
  Future<Response> getDevices() => 
      _dio.get('/api/mobile/auth/devices');

  Future<Response> revokeDevice(String id) => 
      _dio.delete('/api/mobile/auth/devices/$id');

  Future<Response> logoutAllDevices() => 
      _dio.post('/api/mobile/auth/logout-all');

  // Export
  Future<Response> exportScans() => 
      _dio.get('/api/export/scans');
}
