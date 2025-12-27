import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> updateProfile({
    String? name,
    String? language,
    String? timezone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (language != null) data['language'] = language;
      if (timezone != null) data['timezone'] = timezone;

      final response = await _api.updateProfile(data);
      
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      _errorMessage = 'Error al actualizar perfil';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.deleteAccount();
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      _errorMessage = 'Error al eliminar cuenta';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> acceptTerms() async {
    try {
      await _api.acceptTerms();
      return true;
    } catch (e) {
      debugPrint('Accept terms error: $e');
      return false;
    }
  }

  Future<String?> exportScans() async {
    try {
      final response = await _api.exportScans();
      if (response.statusCode == 200) {
        return response.data['url']; // URL del CSV generado
      }
    } catch (e) {
      debugPrint('Export scans error: $e');
      _errorMessage = 'Error al exportar datos';
    }
    return null;
  }
}
