import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../providers/qr_provider.dart';

class QrAnalyticsScreen extends StatefulWidget {
  final String qrId;

  const QrAnalyticsScreen({super.key, required this.qrId});

  @override
  State<QrAnalyticsScreen> createState() => _QrAnalyticsScreenState();
}

class _QrAnalyticsScreenState extends State<QrAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final data = await context.read<QrProvider>().getQrAnalytics(widget.qrId);
    if (mounted) {
      setState(() {
        // Si no hay datos reales (null), usamos mock para la demo visual
        _data = data ?? _getMockData();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getMockData() {
    // Generar datos simulados para demo visual
    final now = DateTime.now();
    final random = math.Random();
    List<Map<String, dynamic>> daily = [];
    
    for (int i = 6; i >= 0; i--) {
      daily.add({
        'date': now.subtract(Duration(days: i)).toIso8601String(),
        'count': random.nextInt(50) + 5,
      });
    }

    return {
      'totalScans': 1245,
      'uniqueScans': 890,
      'topDevice': 'Android',
      'topBrowser': 'Chrome',
      'dailyScans': daily,
      'locations': [
        {'city': 'Buenos Aires', 'count': 450, 'percent': 0.45},
        {'city': 'Córdoba', 'count': 230, 'percent': 0.23},
        {'city': 'Rosario', 'count': 120, 'percent': 0.12},
        {'city': 'Mendoza', 'count': 80, 'percent': 0.08},
        {'city': 'Otros', 'count': 365, 'percent': 0.12},
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    final qr = context.read<QrProvider>().getQrById(widget.qrId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Analíticas'),
        backgroundColor: AppTheme.background,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header QR Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              qr?.name ?? 'QR Sin Nombre',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/${qr?.slug}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                  const Gap(24),

                  // Overview Cards
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Escaneos Totales',
                          value: '${_data!['totalScans']}',
                          icon: Icons.qr_code_scanner_rounded,
                          color: Colors.blue,
                          delay: 100,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _MetricCard(
                          label: 'Únicos',
                          value: '${_data!['uniqueScans']}',
                          icon: Icons.person_outline_rounded,
                          color: Colors.purple,
                          delay: 200,
                        ),
                      ),
                    ],
                  ),

                  const Gap(32),

                  // Chart Section
                  _SectionTitle('Rendimiento (Últimos 7 días)'),
                  const Gap(16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: _SimpleBarChart(data: _data!['dailyScans']),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  const Gap(32),

                  // Top Devices
                  _SectionTitle('Dispositivos y Navegadores'),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Top Dispositivo',
                          value: _data!['topDevice'],
                          icon: Icons.smartphone_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _InfoCard(
                          title: 'Top Navegador',
                          value: _data!['topBrowser'],
                          icon: Icons.web_rounded,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),

                  const Gap(32),

                  // Locations List
                  _SectionTitle('Ubicaciones Principales'),
                  const Gap(16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < (_data!['locations'] as List).length; i++) ...[
                          _LocationRow(
                            data: _data!['locations'][i],
                            isLast: i == (_data!['locations'] as List).length - 1,
                          ),
                        ]
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  
                  const Gap(40),
                ],
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const Gap(16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(begin: const Offset(0.9, 0.9));
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<dynamic> data;

  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('Sin datos'));

    final maxCount = data.map((e) => e['count'] as int).reduce(math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((item) {
            final count = item['count'] as int;
            final date = DateTime.parse(item['date']);
            final height = (count / maxCount) * (constraints.maxHeight - 30);
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 30,
                  height: height < 4 ? 4 : height,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ).animate().scaleY(
                  duration: 800.ms, 
                  curve: Curves.easeOutQuart,
                  alignment: Alignment.bottomCenter,
                ),
                const Gap(8),
                Text(
                  '${date.day}/${date.month}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;

  const _LocationRow({required this.data, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  data['city'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '${data['count']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(data['percent'] * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 20, endIndent: 20, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
