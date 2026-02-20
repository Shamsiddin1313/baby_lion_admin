import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await ApiService().getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('dashboard'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStats,
                tooltip: t('refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${t('error')}: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadStats, child: Text(t('retry'))),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(t('total_users'), '${_stats!['total_users'] ?? 0}', Icons.people, Colors.blue),
                  _buildStatCard(t('total_products'), '${_stats!['total_products'] ?? 0}', Icons.inventory, Colors.green),
                  _buildStatCard(t('total_orders'), '${_stats!['total_orders'] ?? 0}', Icons.shopping_cart, Colors.orange),
                  _buildStatCard(t('paid_orders'), '${_stats!['paid_orders'] ?? 0}', Icons.attach_money, Colors.purple),
                  _buildStatCard(t('total_deliveries'), '${_stats!['total_deliveries'] ?? 0}', Icons.local_shipping, Colors.teal),
                  _buildStatCard(t('delivered'), '${_stats!['delivered'] ?? 0}', Icons.check_circle, Colors.green),
                  if (_stats!['by_status'] != null)
                    ...(_stats!['by_status'] as Map<String, dynamic>).entries.map(
                      (e) => _buildStatCard(
                        t('status_${e.key}'),
                        '${e.value}',
                        Icons.label,
                        Colors.blueGrey,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
