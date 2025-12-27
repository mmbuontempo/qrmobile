import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../auth/providers/auth_provider.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final devices = await context.read<AuthProvider>().getDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDevices();
            },
          ),
          const Gap(8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _devices.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return _DeviceCard(
                      device: device,
                      onRevoke: () => _confirmRevoke(device),
                    );
                  },
                ),
      bottomNavigationBar: _devices.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: _confirmLogoutAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Cerrar todas las demás sesiones'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_rounded, size: 64, color: Theme.of(context).disabledColor),
          const Gap(16),
          Text(
            'No se encontraron dispositivos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(Map<String, dynamic> device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revocar acceso'),
        content: Text('¿Deseas desconectar el dispositivo "${device['deviceName']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<AuthProvider>().revokeDevice(device['id']);
      if (success) {
        _loadDevices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispositivo desconectado')),
          );
        }
      }
    }
  }

  Future<void> _confirmLogoutAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar todas las sesiones'),
        content: const Text('Se cerrará la sesión en TODOS los dispositivos, incluido este. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Todo'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logoutAllDevices();
      if (mounted) {
        Navigator.pop(context); // Close screen, auth provider will trigger redirect to login
      }
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onRevoke;

  const _DeviceCard({required this.device, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final isCurrent = device['isCurrent'] == true;
    final lastActive = DateTime.tryParse(device['lastActive'] ?? '');
    
    // Icon based on OS
    IconData icon = Icons.smartphone_rounded;
    final os = (device['deviceOS'] ?? '').toString().toLowerCase();
    if (os.contains('windows') || os.contains('mac') || os.contains('linux')) {
      icon = Icons.computer_rounded;
    } else if (os.contains('tablet') || os.contains('ipad')) {
      icon = Icons.tablet_mac_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).dividerColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isCurrent ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device['deviceName'] ?? 'Desconocido',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCurrent)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ESTE DISPOSITIVO',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(4),
            Text(device['deviceOS'] ?? 'SO Desconocido'),
            const Gap(4),
            Text(
              lastActive != null 
                  ? 'Activo: ${TimeAgo.format(lastActive)}' 
                  : 'Activo recientemente',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
        trailing: !isCurrent
            ? IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                onPressed: onRevoke,
                tooltip: 'Revocar acceso',
              )
            : null,
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
