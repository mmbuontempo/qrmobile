import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/plan_model.dart';

class BillingProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  SubscriptionModel? _subscription;
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPaid => _subscription?.isPaid ?? false;
  int get qrRemaining => _subscription?.qrRemaining ?? 0;
  bool get canCreateQr => qrRemaining > 0;

  Future<void> loadSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.getSubscription();
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        _subscription = SubscriptionModel.fromJson(data);
      } else {
        _errorMessage = 'Error al cargar suscripción';
      }
    } catch (e) {
      debugPrint('Load subscription error: $e');
      _errorMessage = 'Error de conexión';
      
      // Mock for dev/demo if needed
      /*
      _subscription = SubscriptionModel(
        planKey: 'free',
        planName: 'Starter',
        isPaid: false,
        qrLimit: 1,
        qrUsed: 0,
        qrRemaining: 1,
        features: PlanFeatures(
          microsites: false,
          analytics: true,
          folders: false,
          export: false,
          customDomain: false,
          apiAccess: false,
        ),
      );
      */
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Crear intento de pago (Web Only flow por ahora)
  /// Retorna la URL de pago si es exitoso
  Future<String?> createPaymentIntent(String planId, String period) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.createPaymentIntent({
        'planId': planId,
        'period': period, // 'monthly' | 'yearly'
      });

      if (response.statusCode == 200) {
        final url = response.data['url'];
        return url;
      }
    } catch (e) {
      debugPrint('Create payment error: $e');
      _errorMessage = 'Error al iniciar pago';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
