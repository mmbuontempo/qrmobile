import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Crear Nuevo QR',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del QR',
                  hintText: 'Ej: Menú Restaurante',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  if (_slugController.text.isEmpty || 
                      _slugController.text == _generateSlug(_nameController.text.substring(0, _nameController.text.length - 1))) {
                    _slugController.text = _generateSlug(value);
                  }
                },
                validator: (v) => v?.isEmpty == true ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug (URL corta)',
                  hintText: 'Ej: menu-restaurante',
                  prefixIcon: Icon(Icons.link),
                  prefixText: '/',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Ingresa un slug';
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v!)) {
                    return 'Solo letras minúsculas, números y guiones';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL Destino',
                  hintText: 'https://tu-sitio.com/pagina',
                  prefixIcon: Icon(Icons.open_in_new),
                  border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _createQr,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isLoading ? 'Creando...' : 'Crear QR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(qrProvider.errorMessage ?? 'Error al crear QR'),
            backgroundColor: Colors.red,
          ),
        );
        qrProvider.clearError();
      }
    }
  }
}
