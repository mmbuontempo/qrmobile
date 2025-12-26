import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Verificar si hay sesión activa al iniciar la app
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Primero verificar si hay tokens guardados
      final hasTokens = await _authService.isAuthenticated();
      
      if (hasTokens) {
        // Intentar obtener usuario del servidor
        final user = await _authService.getCurrentUser();
        
        if (user != null) {
          _user = user;
          _status = AuthStatus.authenticated;
        } else {
          // Token expirado, intentar refresh
          final refreshed = await _authService.refreshTokens();
          if (refreshed) {
            _user = await _authService.getCurrentUser();
            _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
          } else {
            _status = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Login con Google Sign-In nativo
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        // Usuario canceló
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _errorMessage = 'Error al iniciar sesión con Google';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Logout completo
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.logout();
    
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
