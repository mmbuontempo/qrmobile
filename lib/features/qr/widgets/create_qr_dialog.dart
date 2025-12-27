import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/qr_provider.dart';

class CreateQrDialog extends StatefulWidget {
  const CreateQrDialog({super.key});

  @override
  State<CreateQrDialog> createState() => _CreateQrDialogState();
}

class _CreateQrDialogState extends State<CreateQrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;

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
              validator: (v) {
                if (v?.isEmpty == true) return 'Ingresa una URL';
                final uri = Uri.tryParse(v!);
                if (uri == null || !uri.hasScheme) {
                  return 'Ingresa una URL válida (con https://)';
                }
                return null;
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            
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

    final qrProvider = context.read<QrProvider>();
    final success = await qrProvider.createQr(
      name: _nameController.text,
      slug: _slugController.text,
      targetUrl: _urlController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
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
