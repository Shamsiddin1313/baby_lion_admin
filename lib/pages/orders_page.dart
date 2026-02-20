import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  static const _statuses = [
    'pending',
    'waiting_payment',
    'paid',
    'preparing',
    'on_the_way',
    'delivered',
    'canceled',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await ApiService().getOrders(limit: 200, status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  void _updateStatus(int orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Order Status'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _statuses.map((status) {
              final isSelected = status == currentStatus;
              return ListTile(
                title: Text(status.replaceAll('_', ' ').toUpperCase()),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blue : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (status == currentStatus) return;
                  try {
                    await ApiService().updateOrderStatus(orderId, status);
                    _loadOrders();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status updated to $status')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'canceled':
      case 'cancelled':
        return Colors.red;
      case 'on_the_way':
        return Colors.orange;
      case 'preparing':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Orders', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('All statuses'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All statuses')),
                      ..._statuses.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.replaceAll('_', ' ').toUpperCase()),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 16),
                  Text('${_orders.length} orders', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders, tooltip: 'Refresh'),
                ],
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
                    Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Order #')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Items')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Payment')),
                      DataColumn(label: Text('Created')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _orders.map((o) {
                      final order = Map<String, dynamic>.from(o);
                      final user = order['user'];
                      final items = order['items'] as List? ?? [];
                      final payment = order['payment'];
                      final status = order['status'] ?? '';
                      final itemsSummary = items.map((i) => '${i['product_name']} x${i['quantity']}').join(', ');

                      return DataRow(cells: [
                        DataCell(Text('${order['id']}')),
                        DataCell(Text(order['order_number'] ?? '')),
                        DataCell(Text(user != null ? '${user['name']}\n${user['phone']}' : '-')),
                        DataCell(SizedBox(width: 200, child: Text(itemsSummary, overflow: TextOverflow.ellipsis, maxLines: 2))),
                        DataCell(Text('${order['total_amount'] ?? 0}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(Text(payment != null ? '${payment['provider'] ?? ''}\n${payment['status'] ?? ''}' : '-')),
                        DataCell(Text(order['created_at']?.toString().substring(0, 19) ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateStatus(order['id'], status),
                            tooltip: 'Update status',
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
