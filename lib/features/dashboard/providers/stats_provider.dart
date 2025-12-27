import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/stats_model.dart';

class StatsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  StatsModel _stats = StatsModel.empty();
  bool _isLoading = false;
  String? _errorMessage;

  StatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters rápidos para la UI
  int get activeQrs => _stats.activeQrs;
  int get totalScans => _stats.totalScans;
  String get planName => _stats.planName ?? 'Starter';
  bool get canCreateQr => (_stats.qrRemaining ?? 0) > 0;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    
    // Use Future.microtask to avoid setState during build
    Future.microtask(() => notifyListeners());

    try {
      final response = await _api.getDashboardStats();
      if (response.statusCode == 200) {
        // La respuesta puede venir envuelta en "data" o directa dependiendo del backend
        final data = response.data['data'] ?? response.data;
        _stats = StatsModel.fromJson(data);
      } else {
        _errorMessage = 'Error al cargar estadísticas';
      }
    } catch (e) {
      debugPrint('Load stats error: $e');
      _errorMessage = 'Error de conexión';
      // Mantenemos los stats vacíos o los anteriores en caso de error
    }

    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<Map<String, dynamic>?> loadAdvancedAnalytics() async {
    try {
      final response = await _api.getGeneralAnalytics();
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
    } catch (e) {
      debugPrint('Advanced analytics error: $e');
    }
    return null;
  }
}
