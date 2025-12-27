import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/stats_provider.dart';
import '../../qr/providers/qr_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../billing/providers/billing_provider.dart';
import '../../billing/screens/billing_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/stats_card.dart';
import '../../qr/screens/qr_list_screen.dart';
import '../../qr/widgets/create_qr_dialog.dart';
import '../../settings/screens/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../settings/screens/devices_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final statsProvider = context.read<StatsProvider>();
    final qrProvider = context.read<QrProvider>();
    final billingProvider = context.read<BillingProvider>();
    
    await Future.wait([
      statsProvider.loadStats(),
      qrProvider.loadQrList(),
      billingProvider.loadSubscription(),
    ]);
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with gestures
        children: [
          _HomeTab(onSwitchTab: _onNavTap),
          const QrListScreen(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          height: 70,
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavTap,
          backgroundColor: Theme.of(context).cardColor,
          indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: const Icon(Icons.qr_code_outlined),
              selectedIcon: Icon(Icons.qr_code_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Mis QRs',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Perfil',
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Function(int) onSwitchTab;

  const _HomeTab({required this.onSwitchTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final statsProvider = context.watch<StatsProvider>();
    final qrProvider = context.watch<QrProvider>();
    final billingProvider = context.watch<BillingProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          statsProvider.loadStats(),
          qrProvider.loadQrList(),
          billingProvider.loadSubscription(),
        ]);
      },
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).cardColor,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('PromusLink'),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 2),
                  ),
                  child: UserAvatar(
                    name: authProvider.user?.name,
                    imageUrl: authProvider.user?.avatarUrl,
                    radius: 20,
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome message
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${authProvider.user?.name?.split(' ').first ?? 'Usuario'}! 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Aquí está el resumen de tu actividad',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
                
                const Gap(24),

                // Plan Usage Card
                if (billingProvider.subscription != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor, 
                          Theme.of(context).primaryColor.withValues(alpha: 0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              billingProvider.subscription!.planName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${billingProvider.subscription!.qrUsed}/${billingProvider.subscription!.qrLimit} QRs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: billingProvider.subscription!.qrLimit > 0 
                                ? billingProvider.subscription!.qrUsed / billingProvider.subscription!.qrLimit
                                : 0,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          billingProvider.canCreateQr 
                              ? 'Puedes crear ${billingProvider.qrRemaining} QRs más'
                              : 'Has alcanzado el límite de tu plan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  const Gap(24),
                ],

                // Stats Grid
                if (statsProvider.isLoading)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: List.generate(4, (index) => const SkeletonLoader(
                      width: double.infinity,
                      height: 100,
                      borderRadius: 20,
                    )),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      StatsCard(
                        title: 'Total QRs',
                        value: qrProvider.qrCount.toString(),
                        icon: Icons.qr_code_2,
                        color: Theme.of(context).primaryColor,
                        delay: 100,
                      ),
                      StatsCard(
                        title: 'QRs Activos',
                        value: qrProvider.activeCount.toString(),
                        icon: Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        delay: 200,
                      ),
                      StatsCard(
                        title: 'Escaneos Hoy',
                        value: statsProvider.stats.scansToday.toString(),
                        icon: Icons.today_rounded,
                        color: Theme.of(context).colorScheme.error,
                        delay: 300,
                      ),
                      StatsCard(
                        title: 'Total Escaneos',
                        value: statsProvider.stats.totalScans.toString(),
                        icon: Icons.insights_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                        delay: 400,
                      ),
                    ],
                  ),

                const Gap(32),

                // Quick Actions
                Text(
                  'Acciones Rápidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                
                const Gap(16),
                
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Crear QR',
                        color: Theme.of(context).primaryColor,
                        delay: 600,
                        onTap: () {
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
                                content: const Text('Límite de plan alcanzado. Actualiza tu plan para crear más QRs.'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                action: SnackBarAction(
                                  label: 'VER PLANES',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => BillingScreen()),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.share_rounded,
                        label: 'Compartir',
                        color: Theme.of(context).colorScheme.secondary,
                        delay: 700,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const Gap(32),

                // Recent QRs Header
                if (qrProvider.qrList.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QRs Recientes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onSwitchTab(1), // Switch to QRs tab
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                  
                  const Gap(12),
                  
                  // Recent List
                  ...qrProvider.qrList.take(3).map((qr) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: qr.isActive 
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                              : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: qr.isActive 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).disabledColor,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        qr.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '/${qr.slug}',
                        style: TextStyle(color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: qr.isActive 
                              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1) 
                              : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          qr.isActive ? 'Activo' : 'Pausado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: qr.isActive ? Theme.of(context).colorScheme.secondary : Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0)),
                  
                  const Gap(80), // Bottom spacing for FAB
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const Gap(12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: delay))
      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final billingProvider = context.watch<BillingProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 2),
                  ),
                  child: UserAvatar(
                    name: authProvider.user?.name,
                    imageUrl: authProvider.user?.avatarUrl,
                    radius: 30,
                    fontSize: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.user?.name ?? 'Usuario',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        authProvider.user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: billingProvider.isPaid 
                              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          billingProvider.subscription?.planName ?? 'Cargando...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: billingProvider.isPaid ? Theme.of(context).colorScheme.secondary : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          const Gap(32),
          
          _SectionTitle('General'),
          const Gap(12),
          
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Mi Cuenta',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.credit_card_outlined,
                title: 'Suscripción y Pagos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BillingScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.devices_other_rounded,
                title: 'Dispositivos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DevicesScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.download_rounded,
                title: 'Exportar Datos (CSV)',
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generando reporte...')),
                  );
                  
                  final url = await context.read<SettingsProvider>().exportScans();
                  
                  if (context.mounted) {
                    if (url != null) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('No se pudo generar el reporte'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente')),
                  );
                },
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          const Gap(24),
          _SectionTitle('Soporte'),
          const Gap(12),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Ayuda y Soporte',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Sobre PromusLink',
                onTap: () {},
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          
          const Gap(24),
          
          FilledButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                await authProvider.logout();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).colorScheme.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 20),
                Gap(8),
                Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          const Gap(40),
          Center(
            child: Text(
              'PromusLink Mobile v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final isLast = index == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5), indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).disabledColor),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
