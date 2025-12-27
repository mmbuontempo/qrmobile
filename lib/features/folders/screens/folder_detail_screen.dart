import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/folder_provider.dart';
import '../../qr/providers/qr_provider.dart';
import '../../../core/models/folder_model.dart';
import '../../qr/widgets/qr_card.dart';
import '../../qr/widgets/create_qr_dialog.dart';
import '../widgets/create_folder_dialog.dart';

class FolderDetailScreen extends StatelessWidget {
  final FolderModel folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final qrProvider = context.watch<QrProvider>();
    
    // Get updated folder data from provider or use passed one
    final currentFolder = folderProvider.folders
        .where((f) => f.id == folder.id)
        .firstOrNull ?? folder;

    // Filter QRs belonging to this folder
    final folderQrs = qrProvider.qrList
        .where((qr) => qr.folderId == folder.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(currentFolder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditDialog(context, currentFolder),
            tooltip: 'Editar Carpeta',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context, currentFolder),
            tooltip: 'Eliminar Carpeta',
          ),
          const Gap(8),
        ],
      ),
      body: folderQrs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(currentFolder.icon),
                      size: 48,
                      color: _getColor(currentFolder.color),
                    ),
                  ).animate().scale(curve: Curves.elasticOut),
                  const Gap(24),
                  Text(
                    'Carpeta vacía',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Mueve QRs existentes o crea uno nuevo aquí',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Gap(32),
                  FilledButton.icon(
                    onPressed: () => _showCreateQrDialog(context, currentFolder.id),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear QR en esta carpeta'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: folderQrs.length,
              itemBuilder: (context, index) {
                return QrCard(
                  qr: folderQrs[index],
                  index: index,
                );
              },
            ),
    );
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      case 'pink': return Colors.pink;
      case 'grey': return Colors.grey;
      default: return Colors.blue;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'work': return Icons.work_rounded;
      case 'star': return Icons.star_rounded;
      case 'home': return Icons.home_rounded;
      case 'tag': return Icons.label_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'event': return Icons.event_rounded;
      default: return Icons.folder_rounded;
    }
  }

  void _showEditDialog(BuildContext context, FolderModel folder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateFolderDialog(folder: folder),
    );
  }

  void _showCreateQrDialog(BuildContext context, String folderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateQrDialog(initialFolderId: folderId), 
    );
  }

  Future<void> _confirmDelete(BuildContext context, FolderModel folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Carpeta'),
        content: const Text('¿Estás seguro? Los QRs dentro NO se eliminarán, solo la carpeta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<FolderProvider>().deleteFolder(folder.id);
      if (success && context.mounted) {
        Navigator.pop(context); // Go back to list
      }
    }
  }
}
