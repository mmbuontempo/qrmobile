class AppConstants {
  static const String appName = 'PromusLink';
  
  // ============================================
  // API Configuration - PRODUCTION
  // ============================================
  static const String apiBaseUrl = 'https://promuslink.com';
  
  // For local development, uncomment this:
  // static const String apiBaseUrl = 'http://10.0.2.2:4000'; // Android emulator
  
  // Google OAuth - Web Client ID (mismo que usa el backend)
  static const String googleWebClientId = '995720787488-1jf9j6t93c7tr4nj1nnl4ugshlbsqgp6.apps.googleusercontent.com';
  
  // Mobile Auth Endpoints
  static const String mobileAuthGoogle = '/api/mobile/auth/google';
  static const String mobileAuthRefresh = '/api/mobile/auth/refresh';
  static const String mobileAuthMe = '/api/mobile/auth/me';
  static const String mobileAuthLogout = '/api/mobile/auth/logout';
  
  // QR URLs
  static const String qrBaseUrl = 'https://promuslink.com/c/';
}
