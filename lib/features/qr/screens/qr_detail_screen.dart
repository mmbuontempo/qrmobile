import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/qr_provider.dart';
import '../../folders/providers/folder_provider.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/models/qr_model.dart';

class QrDetailScreen extends StatefulWidget {
  final String qrId;

  const QrDetailScreen({super.key, required this.qrId});

  @override
  State<QrDetailScreen> createState() => _QrDetailScreenState();
}

class _QrDetailScreenState extends State<QrDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _urlController;
  String? _selectedFolderId;
  bool _isEditing = false;
  bool _isSaving = false;

  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _urlController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQrData();
      context.read<FolderProvider>().loadFolders();
    });
  }

  void _loadQrData() {
    final qr = context.read<QrProvider>().getQrById(widget.qrId);
    if (qr != null) {
      _nameController.text = qr.name;
      _slugController.text = qr.slug;
      _urlController.text = qr.targetUrl ?? '';
      _selectedFolderId = qr.folderId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _urlController.dispose();
    super.dispose();
  }

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
    final qrProvider = context.watch<QrProvider>();
    final folderProvider = context.watch<FolderProvider>();
    final qr = qrProvider.getQrById(widget.qrId);

    if (qr == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('QR no encontrado'), backgroundColor: AppTheme.background),
        body: const Center(child: Text('El QR no existe')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar QR' : 'Detalles del QR'),
        backgroundColor: AppTheme.background,
        centerTitle: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar',
            )
          else
            TextButton(
              onPressed: () {
                _loadQrData();
                setState(() => _isEditing = false);
              },
              child: const Text('Cancelar'),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code Display Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: QrImageView(
                      data: qr.qrUrl,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
                  
                  const Gap(20),
                  
                  InkWell(
                    onTap: () => _copyToClipboard(qr.qrUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCopied 
                            ? AppTheme.success.withOpacity(0.1) 
                            : AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCopied 
                              ? AppTheme.success.withOpacity(0.5) 
                              : AppTheme.primary.withOpacity(0.1)
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              qr.qrUrl,
                              style: TextStyle(
                                color: _isCopied ? AppTheme.success : AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(12),
                          AnimatedSwitcher(
                            duration: 200.ms,
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                              key: ValueKey(_isCopied),
                              size: 16, 
                              color: _isCopied ? AppTheme.success : AppTheme.primary
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const Gap(24),

            // Main Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareQr(qr),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.surface,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => qrProvider.toggleQrStatus(qr),
                    icon: Icon(qr.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(qr.isActive ? 'Pausar' : 'Activar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: qr.isActive ? AppTheme.warning : AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            
            const Gap(24),

            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del QR',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Gap(20),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Ej: QR Menú Principal',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                      ),
                      const Gap(16),
                      
                      TextFormField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug (URL amigable)',
                          hintText: 'Ej: menu-principal',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                      ),
                      const Gap(16),
                      
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Destino',
                          hintText: 'https://ejemplo.com',
                          prefixIcon: Icon(Icons.open_in_new_rounded),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Requerido';
                          if (!Uri.tryParse(v!)!.hasScheme) return 'URL inválida';
                          return null;
                        },
                      ),
                      const Gap(16),

                      DropdownButtonFormField<String>(
                        value: _selectedFolderId,
                        decoration: const InputDecoration(
                          labelText: 'Carpeta',
                          prefixIcon: Icon(Icons.folder_open_rounded),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sin carpeta'),
                          ),
                          ...folderProvider.folders.map((folder) => DropdownMenuItem(
                            value: folder.id,
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 10, color: _getFolderColor(folder.color)),
                                const Gap(8),
                                Text(folder.name),
                              ],
                            ),
                          )),
                        ],
                        onChanged: (v) => setState(() => _selectedFolderId = v),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              )
            ] else ...[
              // Info Display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.label_outline_rounded,
                      label: 'Nombre',
                      value: qr.name,
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      icon: Icons.link_rounded,
                      label: 'Slug',
                      value: '/${qr.slug}',
                      isMonospace: true,
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      icon: Icons.open_in_new_rounded,
                      label: 'URL Destino',
                      value: qr.targetUrl ?? 'No configurado',
                      isLink: true,
                    ),
                    const Divider(height: 32),
                    if (qr.folderId != null) ...[
                      _InfoRow(
                        icon: Icons.folder_outlined,
                        label: 'Carpeta',
                        value: folderProvider.folders
                                .where((f) => f.id == qr.folderId)
                                .firstOrNull
                                ?.name ??
                            'Carpeta no encontrada',
                      ),
                      const Divider(height: 32),
                    ],
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Creado',
                      value: TimeAgo.formatFull(qr.createdAt),
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      icon: Icons.update_rounded,
                      label: 'Actualizado',
                      value: TimeAgo.formatFull(qr.updatedAt),
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Estado',
                      value: qr.isActive ? 'Activo' : 'Pausado',
                      valueColor: qr.isActive ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            ],

            const Gap(32),

            // Delete Button
            FilledButton.icon(
              onPressed: () => _confirmDelete(qr),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Eliminar QR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error.withOpacity(0.1),
                foregroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await context.read<QrProvider>().updateQr(
      widget.qrId,
      {
        'name': _nameController.text,
        'slug': _slugController.text,
        'targetUrl': _urlController.text,
      },
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) _isEditing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR actualizado correctamente')),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => _isCopied = true);
    
    Future.delayed(2.seconds, () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _shareQr(QrModel qr) {
    Share.share(
      'Escanea mi QR: ${qr.qrUrl}',
      subject: qr.name,
    );
  }

  Future<void> _confirmDelete(QrModel qr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar QR'),
        content: Text('¿Estás seguro que deseas eliminar "${qr.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<QrProvider>().deleteQr(qr.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR eliminado')),
        );
      }
    }
  }

  // Removed _formatDate as we use TimeAgo now
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final bool isMonospace;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.isMonospace = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const Gap(4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? (isLink ? AppTheme.primary : AppTheme.textPrimary),
                  fontWeight: FontWeight.w500,
                  fontFamily: isMonospace ? 'monospace' : null,
                  decoration: isLink ? TextDecoration.underline : null,
                  decorationColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
