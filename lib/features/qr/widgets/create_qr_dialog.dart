import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/qr_provider.dart';
import '../../folders/providers/folder_provider.dart';

class CreateQrDialog extends StatefulWidget {
  final String? initialFolderId;

  const CreateQrDialog({super.key, this.initialFolderId});

  @override
  State<CreateQrDialog> createState() => _CreateQrDialogState();
}

class _CreateQrDialogState extends State<CreateQrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _urlController = TextEditingController();
  String? _selectedFolderId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    
    // Cargar carpetas si no están cargadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FolderProvider>().loadFolders();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 24, color: AppTheme.primary),
                ),
                const Gap(16),
                Text(
                  'Crear Nuevo QR',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Gap(24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del QR',
                hintText: 'Ej: Menú Restaurante',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                if (_slugController.text.isEmpty || 
                    _slugController.text == _generateSlug(_nameController.text.substring(0, _nameController.text.length - 1))) {
                  _slugController.text = _generateSlug(value);
                }
              },
              validator: (v) => v?.isEmpty == true ? 'Ingresa un nombre' : null,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const Gap(16),

            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug (URL corta)',
                hintText: 'Ej: menu-restaurante',
                prefixIcon: Icon(Icons.link_rounded),
                prefixText: '/',
              ),
              validator: (v) {
                if (v?.isEmpty == true) return 'Ingresa un slug';
                if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v!)) {
                  return 'Solo letras minúsculas, números y guiones';
                }
                return null;
              },
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const Gap(16),

            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL Destino',
                hintText: 'https://tu-sitio.com/pagina',
                prefixIcon: Icon(Icons.open_in_new_rounded),
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) {
                // Auto-fix URL prefix logic could go here, 
                // but better to do it on validation or submit to not annoy user while typing
              },
              validator: (v) {
                if (v?.isEmpty == true) return 'Ingresa una URL';
                // Allow input without scheme, we will add it later
                var input = v!;
                if (!input.startsWith('http://') && !input.startsWith('https://')) {
                   input = 'https://$input';
                }
                final uri = Uri.tryParse(input);
                if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                  return 'Ingresa una URL válida (ej. google.com)';
                }
                return null;
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const Gap(16),

            Text(
              'Carpeta (Opcional)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const Gap(8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FolderChip(
                    label: 'Sin carpeta',
                    icon: Icons.folder_off_outlined,
                    isSelected: _selectedFolderId == null,
                    onTap: () => setState(() => _selectedFolderId = null),
                  ),
                  const Gap(8),
                  ...folderProvider.folders.map((folder) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FolderChip(
                      label: folder.name,
                      colorName: folder.color,
                      isSelected: _selectedFolderId == folder.id,
                      onTap: () => setState(() => _selectedFolderId = folder.id),
                    ),
                  )),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
            
            const Gap(32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.divider),
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _createQr,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      _isLoading ? 'Creando...' : 'Crear QR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Future<void> _createQr() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    var targetUrl = _urlController.text;
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    final qrProvider = context.read<QrProvider>();
    final success = await qrProvider.createQr(
      name: _nameController.text,
      slug: _slugController.text,
      targetUrl: targetUrl,
      folderId: _selectedFolderId,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR creado correctamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(qrProvider.errorMessage ?? 'Error al crear QR'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        qrProvider.clearError();
      }
    }
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final String? colorName;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FolderChip({
    required this.label,
    this.colorName,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  Color _getFolderColor(String? colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorName != null ? _getFolderColor(colorName) : AppTheme.textSecondary;
    final backgroundColor = isSelected 
        ? (colorName != null ? color.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1)) 
        : AppTheme.surface;
    final borderColor = isSelected 
        ? (colorName != null ? color : AppTheme.primary) 
        : AppTheme.divider;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
                const Gap(8),
              ] else if (colorName != null) ...[
                Icon(Icons.folder_rounded, size: 18, color: color),
                const Gap(8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? (colorName != null ? color : AppTheme.primary) 
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (isSelected) ...[
                const Gap(8),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colorName != null ? color : AppTheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
