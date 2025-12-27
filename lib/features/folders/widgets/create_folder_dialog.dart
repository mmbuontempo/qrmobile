import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/folder_provider.dart';
import '../../../core/models/folder_model.dart';

class CreateFolderDialog extends StatefulWidget {
  final FolderModel? folder;

  const CreateFolderDialog({super.key, this.folder});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = 'blue';
  String _selectedIcon = 'folder';
  bool _isLoading = false;

  final Map<String, Color> _colors = {
    'blue': Colors.blue,
    'red': Colors.red,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'teal': Colors.teal,
    'pink': Colors.pink,
    'grey': Colors.grey,
  };

  final Map<String, IconData> _icons = {
    'folder': Icons.folder_rounded,
    'work': Icons.work_rounded,
    'star': Icons.star_rounded,
    'home': Icons.home_rounded,
    'tag': Icons.label_rounded,
    'restaurant': Icons.restaurant_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'event': Icons.event_rounded,
  };

  @override
  void initState() {
    super.initState();
    if (widget.folder != null) {
      _nameController.text = widget.folder!.name;
      _selectedColor = widget.folder!.color ?? 'blue';
      _selectedIcon = widget.folder!.icon ?? 'folder';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.folder == null ? 'Nueva Carpeta' : 'Editar Carpeta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Marketing',
                prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.isEmpty == true ? 'Ingresa un nombre' : null,
            ),
            
            const Gap(20),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final entry = _colors.entries.elementAt(index);
                  final isSelected = _selectedColor == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = entry.key),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: entry.value.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? entry.value : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected 
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Gap(20),
            Text('Icono', style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final entry = _icons.entries.elementAt(index);
                  final isSelected = _selectedIcon == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = entry.key),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),

            const Gap(32),

            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.folder == null ? 'Crear Carpeta' : 'Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<FolderProvider>();
    
    bool success;
    if (widget.folder == null) {
      success = await provider.createFolder(
        _nameController.text,
        color: _selectedColor,
        icon: _selectedIcon,
      );
    } else {
      success = await provider.updateFolder(
        widget.folder!.id,
        {
          'name': _nameController.text,
          'color': _selectedColor,
          'icon': _selectedIcon,
        },
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.folder == null ? 'Carpeta creada' : 'Carpeta actualizada'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al guardar'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
