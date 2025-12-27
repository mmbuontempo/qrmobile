import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/folder_provider.dart';
import '../../../core/models/folder_model.dart';
import '../widgets/create_folder_dialog.dart';

import 'folder_detail_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FolderProvider>().loadFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();

    if (folderProvider.isLoading && folderProvider.folders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (folderProvider.folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.textSecondary),
            const Gap(16),
            Text(
              'Sin carpetas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.create_new_folder_rounded),
              label: const Text('Crear Carpeta'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.create_new_folder_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () => folderProvider.loadFolders(),
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: folderProvider.folders.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, index) {
            final folder = folderProvider.folders[index];
            return _FolderCard(folder: folder);
          },
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, [FolderModel? folder]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateFolderDialog(folder: folder),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FolderModel folder;

  const _FolderCard({required this.folder});

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

  @override
  Widget build(BuildContext context) {
    final color = _getColor(folder.color);
    final icon = _getIcon(folder.icon);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FolderDetailScreen(folder: folder),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${folder.qrCount} QRs',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
              onSelected: (value) {
                if (value == 'edit') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CreateFolderDialog(folder: folder),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      Gap(8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                      Gap(8),
                      Text('Eliminar', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Carpeta'),
        content: const Text('¿Estás seguro? Los QRs dentro no se eliminarán, solo la carpeta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<FolderProvider>().deleteFolder(folder.id);
    }
  }
}
