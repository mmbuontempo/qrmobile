import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/billing_provider.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final billingProvider = context.watch<BillingProvider>();
    final subscription = billingProvider.subscription;

    if (billingProvider.isLoading && subscription == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => billingProvider.loadSubscription(),
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current Plan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                  Theme.of(context).primaryColor, 
                  Theme.of(context).primaryColor.withValues(alpha: 0.9)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
              child: Column(
                children: [
                  const Text(
                    'PLAN ACTUAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    subscription?.planName ?? 'Starter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subscription?.isPaid == true ? 'Activo' : 'Gratuito',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Gap(24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatItem(
                        label: 'QRs Usados',
                        value: '${subscription?.qrUsed ?? 0}',
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _StatItem(
                        label: 'Límite',
                        value: '${subscription?.qrLimit ?? 1}',
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(),

            const Gap(32),

            _SectionTitle('Características del Plan'),
            const Gap(16),

            if (subscription != null) ...[
              _FeatureTile(
                icon: Icons.qr_code_2_rounded,
                label: 'Creación de QRs Dinámicos',
                isEnabled: true,
              ),
              _FeatureTile(
                icon: Icons.analytics_outlined,
                label: 'Analíticas Básicas',
                isEnabled: subscription.features.analytics,
              ),
              _FeatureTile(
                icon: Icons.folder_outlined,
                label: 'Organización en Carpetas',
                isEnabled: subscription.features.folders,
              ),
              _FeatureTile(
                icon: Icons.web_rounded,
                label: 'Micrositios',
                isEnabled: subscription.features.microsites,
              ),
              _FeatureTile(
                icon: Icons.file_download_outlined,
                label: 'Exportación de Datos',
                isEnabled: subscription.features.export,
              ),
              _FeatureTile(
                icon: Icons.api_rounded,
                label: 'Acceso a API',
                isEnabled: subscription.features.apiAccess,
              ),
            ],

            const Gap(32),

            if (subscription?.planKey == 'free')
              FilledButton.icon(
                onPressed: _openUpgradeUrl,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('MEJORAR MI PLAN'),
              ).animate().shimmer(delay: 1.seconds, duration: 2.seconds),

            const Gap(24),
            
            Text(
              'La gestión de pagos se realiza de forma segura a través de nuestro portal web.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpgradeUrl() async {
    const url = 'https://promuslink.com/app/billing'; // Deep link compatible URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.success.withValues(alpha: 0.1) : Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppTheme.success : Theme.of(context).disabledColor,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isEnabled ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).disabledColor,
          decoration: isEnabled ? null : TextDecoration.lineThrough,
        ),
      ),
      trailing: isEnabled
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20)
          : Icon(Icons.lock_outline_rounded, color: Theme.of(context).disabledColor, size: 20),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
