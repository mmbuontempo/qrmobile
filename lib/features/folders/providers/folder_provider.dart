import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/folder_model.dart';

class FolderProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<FolderModel> _folders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FolderModel> get folders => _folders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFolders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.getFolders();
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        _folders = data.map((e) => FolderModel.fromJson(e)).toList();
      } else {
        _errorMessage = 'Error al cargar carpetas';
      }
    } catch (e) {
      debugPrint('Load folders error: $e');
      _errorMessage = 'Error de conexión';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createFolder(String name, {String? color, String? icon}) async {
    try {
      final response = await _api.createFolder({
        'name': name,
        'color': color,
        'icon': icon,
      });

      if (response.statusCode == 201) {
        await loadFolders();
        return true;
      }
    } catch (e) {
      debugPrint('Create folder error: $e');
      _errorMessage = 'Error al crear carpeta';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateFolder(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.updateFolder(id, data);
      if (response.statusCode == 200) {
        await loadFolders();
        return true;
      }
    } catch (e) {
      debugPrint('Update folder error: $e');
      _errorMessage = 'Error al actualizar carpeta';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteFolder(String id) async {
    try {
      final response = await _api.deleteFolder(id);
      if (response.statusCode == 200) {
        _folders.removeWhere((f) => f.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Delete folder error: $e');
      _errorMessage = 'Error al eliminar carpeta';
    }
    notifyListeners();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
