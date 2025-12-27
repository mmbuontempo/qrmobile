import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/qr_provider.dart';
import '../../../core/models/qr_model.dart';
import '../screens/qr_detail_screen.dart';
import '../screens/qr_analytics_screen.dart';
import '../../billing/providers/billing_provider.dart';
import '../../dashboard/providers/stats_provider.dart';

class QrCard extends StatelessWidget {
  final QrModel qr;
  final int index;
  final VoidCallback? onTap;

  const QrCard({
    super.key,
    required this.qr,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qrProvider = context.read<QrProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap ?? () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrDetailScreen(qrId: qr.id)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Preview
                Hero(
                  tag: 'qr_${qr.id}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: QrImageView(
                        data: qr.qrUrl,
                        version: QrVersions.auto,
                        size: 80,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              qr.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          _StatusBadge(isActive: qr.isActive),
                        ],
                      ),
                      const Gap(4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '/${qr.slug}',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (qr.targetUrl != null) ...[
                        const Gap(6),
                        Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 14, color: AppTheme.textSecondary),
                            const Gap(4),
                            Expanded(
                              child: Text(
                                qr.targetUrl!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Gap(12),
                      
                      // Actions
                      Row(
                        children: [
                          _ActionChip(
                            icon: Icons.share_rounded,
                            label: 'Compartir',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _shareQr(context, qr);
                            },
                          ),
                          const Gap(8),
                          _ActionChip(
                            icon: qr.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            label: qr.isActive ? 'Pausar' : 'Activar',
                            color: qr.isActive ? AppTheme.warning : AppTheme.success,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              qrProvider.toggleQrStatus(qr);
                            },
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                            onSelected: (value) async {
                              if (value == 'duplicate') {
                                _confirmDuplicate(context, qr);
                              } else if (value == 'delete') {
                                _confirmDelete(context, qr);
                              } else if (value == 'analytics') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => QrAnalyticsScreen(qrId: qr.id)),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'analytics',
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics_outlined, size: 20),
                                    Gap(8),
                                    Text('Analíticas'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded, size: 20),
                                    Gap(8),
                                    Text('Duplicar'),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
  }

  void _shareQr(BuildContext context, QrModel qr) {
    Share.share(
      'Escanea mi QR: ${qr.qrUrl}',
      subject: qr.name,
    );
  }

  Future<void> _confirmDuplicate(BuildContext context, QrModel qr) async {
    final billingProvider = context.read<BillingProvider>();
    if (!billingProvider.canCreateQr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Límite de plan alcanzado'),
          action: SnackBarAction(label: 'MEJORAR', onPressed: () {}),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar QR'),
        content: Text('¿Deseas crear una copia de "${qr.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<QrProvider>().duplicateQr(qr);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR duplicado exitosamente')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, QrModel qr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar QR'),
        content: Text('¿Estás seguro de eliminar "${qr.name}"? Esta acción no se puede deshacer.'),
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
      final success = await context.read<QrProvider>().deleteQr(qr.id);
      if (success && context.mounted) {
        // Actualizar stats también
        context.read<StatsProvider>().loadStats();
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.success.withOpacity(0.1) 
            : AppTheme.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
          const Gap(4),
          Text(
            isActive ? 'Activo' : 'Pausado',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.textSecondary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: chipColor),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
