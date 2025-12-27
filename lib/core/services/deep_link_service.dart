import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  static DeepLinkService get instance => _instance;

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService._internal();

  void init({
    required Function(String code) onAuthCode,
    required Function() onBillingSuccess,
  }) {
    // Check initial link
    _checkInitialLink(onAuthCode, onBillingSuccess);

    // Listen to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri, onAuthCode, onBillingSuccess);
    });
  }

  Future<void> _checkInitialLink(
    Function(String code) onAuthCode,
    Function() onBillingSuccess,
  ) async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleLink(uri, onAuthCode, onBillingSuccess);
      }
    } catch (e) {
      debugPrint('Error checking initial link: $e');
    }
  }

  void _handleLink(
    Uri uri,
    Function(String code) onAuthCode,
    Function() onBillingSuccess,
  ) {
    debugPrint('Deep link received: $uri');
    
    // Support both custom scheme (promuslink://) and universal links (https://promuslink.com/app/...)
    // Paths:
    // /billing-success -> Refresh billing
    // /auth-callback?code=... -> Login with code
    
    if (uri.toString().contains('billing-success')) {
      onBillingSuccess();
    } else if (uri.toString().contains('auth-callback') && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        onAuthCode(code);
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
