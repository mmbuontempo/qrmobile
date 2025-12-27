import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/stats_provider.dart';
import '../../qr/providers/qr_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/stats_card.dart';
import '../../qr/screens/qr_list_screen.dart';

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
    
    await Future.wait([
      statsProvider.loadStats(),
      qrProvider.loadQrList(),
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
      backgroundColor: AppTheme.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with gestures
        children: const [
          _HomeTab(),
          QrListScreen(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primary.withOpacity(0.1),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded, color: AppTheme.primary),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: const Icon(Icons.qr_code_outlined),
              selectedIcon: const Icon(Icons.qr_code_rounded, color: AppTheme.primary),
              label: 'Mis QRs',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Perfil',
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final statsProvider = context.watch<StatsProvider>();
    final qrProvider = context.watch<QrProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          statsProvider.loadStats(),
          qrProvider.loadQrList(),
        ]);
      },
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('PromusLink'),
            centerTitle: false,
            backgroundColor: AppTheme.background,
            surfaceTintColor: AppTheme.background,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: authProvider.user?.avatarUrl != null
                        ? NetworkImage(authProvider.user!.avatarUrl!)
                        : null,
                    child: authProvider.user?.avatarUrl == null
                        ? Text(
                            authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          )
                        : null,
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
                      '¡Hola, ${authProvider.user?.name?.split(' ').first ?? 'Usuario'}! 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Aquí está el resumen de tu actividad',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
                
                const Gap(24),

                // Stats Grid
                if (statsProvider.isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
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
                        color: AppTheme.primary,
                        delay: 100,
                      ),
                      StatsCard(
                        title: 'QRs Activos',
                        value: qrProvider.activeCount.toString(),
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.success,
                        delay: 200,
                      ),
                      StatsCard(
                        title: 'Escaneos Hoy',
                        value: statsProvider.stats.scansToday.toString(),
                        icon: Icons.today_rounded,
                        color: AppTheme.warning,
                        delay: 300,
                      ),
                      StatsCard(
                        title: 'Total Escaneos',
                        value: statsProvider.stats.totalScans.toString(),
                        icon: Icons.insights_rounded,
                        color: AppTheme.secondary,
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
                    color: AppTheme.textPrimary,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                
                const Gap(16),
                
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Crear QR',
                        color: AppTheme.primary,
                        delay: 600,
                        onTap: () {
                          // Navigate to QR tab? Or open dialog
                          // For now, let's suggest switching to tab 1
                        },
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.share_rounded,
                        label: 'Compartir',
                        color: Colors.teal,
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
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {}, // Navigate to tab 1
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
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
                              ? AppTheme.primary.withOpacity(0.1) 
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: qr.isActive 
                              ? AppTheme.primary 
                              : Colors.grey,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        qr.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '/${qr.slug}',
                        style: TextStyle(color: AppTheme.primary.withOpacity(0.8)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: qr.isActive 
                              ? AppTheme.success.withOpacity(0.1) 
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          qr.isActive ? 'Activo' : 'Pausado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: qr.isActive ? AppTheme.success : Colors.grey,
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
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: authProvider.user?.avatarUrl != null
                        ? NetworkImage(authProvider.user!.avatarUrl!)
                        : null,
                    child: authProvider.user?.avatarUrl == null
                        ? Text(
                            authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          )
                        : null,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Plan Gratuito', // TODO: Fetch plan
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
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
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                onTap: () {},
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
                        backgroundColor: AppTheme.error,
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
              backgroundColor: AppTheme.error.withOpacity(0.1),
              foregroundColor: AppTheme.error,
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
                color: AppTheme.textSecondary.withOpacity(0.5),
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
          color: AppTheme.textSecondary,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final isLast = index == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(height: 1, color: AppTheme.divider.withOpacity(0.5), indent: 56),
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
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
