import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Servicio de Google Sign-In nativo
class GoogleAuthService {
  // Web Client ID de Google Cloud Console (mismo que usa el backend)
  static const _webClientId = '995720787488-1jf9j6t93c7tr4nj1nnl4ugshlbsqgp6.apps.googleusercontent.com';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _webClientId,
  );

  /// Iniciar sesión con Google
  /// Retorna el idToken o null si el usuario canceló
  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        // Usuario canceló
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Cerrar sesión de Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Verificar si hay sesión activa de Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Obtener cuenta actual sin iniciar flujo de login
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    return _googleSignIn.currentUser;
  }
}
