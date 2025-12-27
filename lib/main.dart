import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/qr/providers/qr_provider.dart';
import 'features/dashboard/providers/stats_provider.dart';
import 'core/api/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QrProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const PromusLinkApp(),
    ),
  );
}

/// Configurar callback para sesión expirada (llamar desde App)
void setupSessionExpiredHandler(BuildContext context) {
  ApiClient.onSessionExpired = () {
    final authProvider = context.read<AuthProvider>();
    authProvider.logout();
  };
}
