import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/qr_provider.dart';
import '../../../core/models/qr_model.dart';
import 'qr_detail_screen.dart';
import '../widgets/create_qr_dialog.dart';

class QrListScreen extends StatelessWidget {
  const QrListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final qrProvider = context.watch<QrProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis QRs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => qrProvider.loadQrList(),
          ),
        ],
      ),
      body: _buildBody(context, qrProvider, colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Crear QR'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, QrProvider qrProvider, ColorScheme colorScheme) {
    if (qrProvider.status == QrLoadingStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (qrProvider.status == QrLoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(qrProvider.errorMessage ?? 'Error al cargar'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => qrProvider.loadQrList(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (qrProvider.qrList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No tienes QRs todavía',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer QR dinámico',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear QR'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => qrProvider.loadQrList(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: qrProvider.qrList.length,
        itemBuilder: (context, index) {
          final qr = qrProvider.qrList[index];
          return _QrCard(qr: qr);
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const CreateQrDialog(),
    );
  }
}

class _QrCard extends StatelessWidget {
  final QrModel qr;

  const _QrCard({required this.qr});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final qrProvider = context.read<QrProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QrDetailScreen(qrId: qr.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // QR Preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: QrImageView(
                  data: qr.qrUrl,
                  version: QrVersions.auto,
                  size: 80,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            qr.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: qr.isActive 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            qr.isActive ? 'Activo' : 'Pausado',
                            style: TextStyle(
                              fontSize: 12,
                              color: qr.isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/${qr.slug}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    if (qr.targetUrl != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        qr.targetUrl!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    
                    // Actions
                    Row(
                      children: [
                        _ActionChip(
                          icon: Icons.share,
                          label: 'Compartir',
                          onTap: () => _shareQr(context, qr),
                        ),
                        const SizedBox(width: 8),
                        _ActionChip(
                          icon: qr.isActive ? Icons.pause : Icons.play_arrow,
                          label: qr.isActive ? 'Pausar' : 'Activar',
                          onTap: () => qrProvider.toggleQrStatus(qr),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQr(BuildContext context, QrModel qr) {
    Share.share(
      'Escanea mi QR: ${qr.qrUrl}',
      subject: qr.name,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
