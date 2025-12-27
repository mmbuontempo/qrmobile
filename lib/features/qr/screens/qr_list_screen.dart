import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/qr_provider.dart';
import '../../billing/providers/billing_provider.dart';
import '../widgets/create_qr_dialog.dart';
import '../widgets/qr_card.dart';
import '../../folders/screens/folders_screen.dart';

class QrListScreen extends StatelessWidget {
  const QrListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Mis QRs'),
          backgroundColor: AppTheme.background,
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Todos'),
              Tab(text: 'Carpetas'),
            ],
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                context.read<QrProvider>().loadQrList();
              },
              tooltip: 'Actualizar',
            ),
            const Gap(8),
          ],
        ),
        body: const TabBarView(
          children: [
            _QrListTab(),
            FoldersScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear QR', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final billingProvider = context.read<BillingProvider>();
    if (billingProvider.canCreateQr) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const CreateQrDialog(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Límite de plan alcanzado'),
          backgroundColor: AppTheme.warning,
          action: SnackBarAction(label: 'VER PLANES', onPressed: () {}), // TODO: Go to billing
        ),
      );
    }
  }
}

class _QrListTab extends StatefulWidget {
  const _QrListTab();

  @override
  State<_QrListTab> createState() => _QrListTabState();
}

class _QrListTabState extends State<_QrListTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrProvider = context.watch<QrProvider>();

    if (qrProvider.status == QrLoadingStatus.loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (_, __) => const Gap(16),
        itemBuilder: (_, __) => const SkeletonLoader(
          width: double.infinity,
          height: 100,
          borderRadius: 20,
        ),
      );
    }

    if (qrProvider.status == QrLoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            ).animate().scale(curve: Curves.elasticOut),
            const Gap(24),
            Text(
              qrProvider.errorMessage ?? 'Error al cargar',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: () => qrProvider.loadQrList(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (qrProvider.qrList.isEmpty && _searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 64, color: AppTheme.primaryLight),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const Gap(24),
            Text(
              'No tienes QRs todavía',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const Gap(8),
            Text(
              'Crea tu primer QR dinámico para empezar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      );
    }

    final filteredList = qrProvider.qrList.where((qr) {
      final query = _searchQuery.toLowerCase();
      return qr.name.toLowerCase().contains(query) || 
             qr.slug.toLowerCase().contains(query) ||
             (qr.targetUrl?.toLowerCase().contains(query) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => qrProvider.loadQrList(),
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar QR...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              ),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSecondary),
                        const Gap(16),
                        Text(
                          'No se encontraron resultados',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final qr = filteredList[index];
                      return QrCard(qr: qr, index: index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
