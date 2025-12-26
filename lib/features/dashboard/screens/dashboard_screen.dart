import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          _HomeTab(),
          QrListScreen(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          height: 65,
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavTap,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor: colorScheme.primaryContainer,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_outlined),
              selectedIcon: Icon(Icons.qr_code_rounded),
              label: 'Mis QRs',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          statsProvider.loadStats(),
          qrProvider.loadQrList(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('PromusLink'),
            actions: [
              if (authProvider.user?.avatarUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(authProvider.user!.avatarUrl!),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome message
                Text(
                  '¡Hola, ${authProvider.user?.name?.split(' ').first ?? 'Usuario'}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aquí está el resumen de tus QRs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Grid
                if (statsProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatsCard(
                        title: 'Total QRs',
                        value: qrProvider.qrCount.toString(),
                        icon: Icons.qr_code_2,
                        color: colorScheme.primary,
                      ),
                      StatsCard(
                        title: 'QRs Activos',
                        value: qrProvider.activeCount.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      StatsCard(
                        title: 'Escaneos Hoy',
                        value: statsProvider.stats.scansToday.toString(),
                        icon: Icons.today,
                        color: Colors.orange,
                      ),
                      StatsCard(
                        title: 'Total Escaneos',
                        value: statsProvider.stats.totalScans.toString(),
                        icon: Icons.analytics,
                        color: Colors.purple,
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Acciones Rápidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle,
                        label: 'Crear QR',
                        color: colorScheme.primary,
                        onTap: () {
                          // Navigate to QR tab
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.share,
                        label: 'Compartir',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent QRs
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
                        onPressed: () {},
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...qrProvider.qrList.take(3).map((qr) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: qr.isActive 
                              ? colorScheme.primaryContainer 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color: qr.isActive 
                              ? colorScheme.onPrimaryContainer 
                              : Colors.grey,
                        ),
                      ),
                      title: Text(qr.name),
                      subtitle: Text(qr.slug),
                      trailing: Icon(
                        qr.isActive ? Icons.check_circle : Icons.pause_circle,
                        color: qr.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  )),
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

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          // User Info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: authProvider.user?.avatarUrl != null
                      ? NetworkImage(authProvider.user!.avatarUrl!)
                      : null,
                  child: authProvider.user?.avatarUrl == null
                      ? Text(
                          authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.user?.name ?? 'Usuario',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        authProvider.user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Cuenta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Apariencia'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ayuda'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
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
          ),
          
          const SizedBox(height: 24),
          Center(
            child: Text(
              'PromusLink v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
