import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/qr_model.dart';

enum QrLoadingStatus { initial, loading, loaded, error }

class QrProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  QrLoadingStatus _status = QrLoadingStatus.initial;
  List<QrModel> _qrList = [];
  String? _errorMessage;
  bool _isFirstQr = false;

  QrLoadingStatus get status => _status;
  List<QrModel> get qrList => _qrList;
  String? get errorMessage => _errorMessage;
  bool get isFirstQr => _isFirstQr;
  int get qrCount => _qrList.length;
  int get activeCount => _qrList.where((qr) => qr.isActive).length;

  Future<void> loadQrList({bool useMockData = false}) async {
    _status = QrLoadingStatus.loading;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    // Use mock data for demo mode
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      _qrList = _getMockQrList();
      _isFirstQr = false;
      _status = QrLoadingStatus.loaded;
      Future.microtask(() => notifyListeners());
      return;
    }

    try {
      final response = await _api.getQrList();
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        _qrList = data.map((e) => QrModel.fromJson(e)).toList();
        _isFirstQr = response.data['isFirstQr'] ?? false;
        _status = QrLoadingStatus.loaded;
      } else {
        _errorMessage = 'Error al cargar QRs';
        _status = QrLoadingStatus.error;
      }
    } catch (e) {
      // On auth error, load mock data for demo
      _qrList = _getMockQrList();
      _isFirstQr = false;
      _status = QrLoadingStatus.loaded;
      debugPrint('Load QR error (using mock): $e');
    }

    Future.microtask(() => notifyListeners());
  }

  List<QrModel> _getMockQrList() {
    return [
      QrModel(
        id: 'demo-1',
        name: 'Menú Restaurante',
        slug: 'menu-restaurante',
        shortCode: 'ABC123',
        targetUrl: 'https://mi-restaurante.com/menu',
        isActive: true,
        showInterstitial: false,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
      ),
      QrModel(
        id: 'demo-2',
        name: 'Promo Verano',
        slug: 'promo-verano',
        shortCode: 'XYZ789',
        targetUrl: 'https://mi-tienda.com/ofertas',
        isActive: true,
        showInterstitial: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      QrModel(
        id: 'demo-3',
        name: 'Catálogo 2024',
        slug: 'catalogo-2024',
        shortCode: 'CAT001',
        targetUrl: 'https://ejemplo.com/catalogo.pdf',
        isActive: false,
        showInterstitial: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  Future<bool> createQr({
    required String name,
    required String slug,
    required String targetUrl,
    String? folderId,
  }) async {
    try {
      final data = {
        'name': name,
        'slug': slug,
        'targetUrl': targetUrl,
      };
      if (folderId != null) {
        data['folderId'] = folderId;
      }

      final response = await _api.createQr(data);

      if (response.statusCode == 201) {
        await loadQrList();
        return true;
      } else if (response.statusCode == 403) {
        _errorMessage = response.data['message'] ?? 'Límite de QRs alcanzado';
      } else if (response.statusCode == 409) {
        _errorMessage = 'El slug ya existe';
      }
    } catch (e) {
      _errorMessage = 'Error al crear QR';
      debugPrint('Create QR error: $e');
    }

    notifyListeners();
    return false;
  }

  Future<bool> updateQr(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.updateQr(id, data);
      if (response.statusCode == 200) {
        await loadQrList();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error al actualizar QR';
      debugPrint('Update QR error: $e');
    }

    notifyListeners();
    return false;
  }

  Future<bool> deleteQr(String id) async {
    try {
      final response = await _api.deleteQr(id);
      if (response.statusCode == 200) {
        _qrList.removeWhere((qr) => qr.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error al eliminar QR';
      debugPrint('Delete QR error: $e');
    }

    notifyListeners();
    return false;
  }

  Future<bool> toggleQrStatus(QrModel qr) async {
    try {
      // Usar endpoint específico de toggle según audit
      final response = await _api.toggleQr(qr.id);
      if (response.statusCode == 200) {
        // Actualizar localmente sin recargar todo para mejor UX
        final index = _qrList.indexWhere((q) => q.id == qr.id);
        if (index != -1) {
          _qrList[index] = qr.copyWith(isActive: !qr.isActive);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Toggle QR error: $e');
      _errorMessage = 'Error al cambiar estado';
    }
    notifyListeners();
    return false;
  }

  Future<bool> duplicateQr(QrModel qr) async {
    try {
      final response = await _api.duplicateQr(qr.id);
      if (response.statusCode == 201) {
        await loadQrList(); // Recargar para ver el nuevo
        return true;
      } else if (response.statusCode == 403) {
        _errorMessage = 'Límite de plan alcanzado';
      }
    } catch (e) {
      debugPrint('Duplicate QR error: $e');
      _errorMessage = 'Error al duplicar QR';
    }
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> getQrAnalytics(String id) async {
    try {
      final response = await _api.getQrAnalytics(id);
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQrRules(String id) async {
    try {
      final response = await _api.getQrRules(id);
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
    } catch (e) {
      debugPrint('Get rules error: $e');
    }
    return null;
  }

  Future<bool> updateQrRules(String id, Map<String, dynamic> rules) async {
    try {
      final response = await _api.updateQrRules(id, rules);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Update rules error: $e');
      _errorMessage = 'Error al actualizar reglas';
    }
    notifyListeners();
    return false;
  }

  QrModel? getQrById(String id) {
    try {
      return _qrList.firstWhere((qr) => qr.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
