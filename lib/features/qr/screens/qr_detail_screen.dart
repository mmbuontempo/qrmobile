import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/qr_provider.dart';
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
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _urlController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQrData();
    });
  }

  void _loadQrData() {
    final qr = context.read<QrProvider>().getQrById(widget.qrId);
    if (qr != null) {
      _nameController.text = qr.name;
      _slugController.text = qr.slug;
      _urlController.text = qr.targetUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrProvider = context.watch<QrProvider>();
    final qr = qrProvider.getQrById(widget.qrId);
    final colorScheme = Theme.of(context).colorScheme;

    if (qr == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR no encontrado')),
        body: const Center(child: Text('El QR no existe')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar QR' : qr.name),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
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
                  : const Text('Guardar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code Display
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qr.qrUrl,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // QR URL
            Center(
              child: InkWell(
                onTap: () => _copyToClipboard(qr.qrUrl),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        qr.qrUrl,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy, size: 16, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareQr(qr),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => qrProvider.toggleQrStatus(qr),
                    icon: Icon(qr.isActive ? Icons.pause : Icons.play_arrow),
                    label: Text(qr.isActive ? 'Pausar' : 'Activar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: qr.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: qr.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      qr.isActive ? 'QR Activo' : 'QR Pausado',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      'Código: ${qr.shortCode}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Edit Form
            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del QR',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: QR Menú Principal',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _slugController,
                      decoration: const InputDecoration(
                        labelText: 'Slug',
                        hintText: 'Ej: menu-principal',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Destino',
                        hintText: 'https://ejemplo.com',
                        prefixIcon: Icon(Icons.open_in_new),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Requerido';
                        if (!Uri.tryParse(v!)!.hasScheme) return 'URL inválida';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Info Display
              _InfoTile(
                icon: Icons.label,
                label: 'Nombre',
                value: qr.name,
              ),
              _InfoTile(
                icon: Icons.link,
                label: 'Slug',
                value: '/${qr.slug}',
              ),
              _InfoTile(
                icon: Icons.open_in_new,
                label: 'URL Destino',
                value: qr.targetUrl ?? 'No configurado',
              ),
              _InfoTile(
                icon: Icons.calendar_today,
                label: 'Creado',
                value: _formatDate(qr.createdAt),
              ),
              _InfoTile(
                icon: Icons.update,
                label: 'Actualizado',
                value: _formatDate(qr.updatedAt),
              ),
            ],

            const SizedBox(height: 32),

            // Delete Button
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(qr),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Eliminar QR', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copiada al portapapeles')),
    );
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
