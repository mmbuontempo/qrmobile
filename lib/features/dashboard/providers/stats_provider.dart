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

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    
    // Use Future.microtask to avoid setState during build
    Future.microtask(() => notifyListeners());

    try {
      final response = await _api.getDashboardStats();
      if (response.statusCode == 200) {
        _stats = StatsModel.fromJson(response.data);
      }
    } catch (e) {
      // On error, use mock stats for demo
      _stats = StatsModel(
        totalQrs: 3,
        activeQrs: 2,
        totalScans: 156,
        scansToday: 12,
        scansThisWeek: 45,
        scansThisMonth: 156,
        dailyScans: [],
      );
      debugPrint('Load stats error (using mock): $e');
    }

    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }
}
