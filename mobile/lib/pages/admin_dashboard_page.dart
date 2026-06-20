import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Order> _orders = [];
  bool _isLoadingOrders = true;

  String _searchText = '';
  String _statusFilter = 'all';

  final List<Map<String, String>> lifecycleStatuses = [
    {'key': 'created', 'label': 'Order Created'},
    {'key': 'pickup_scheduled', 'label': 'Pickup Scheduled'},
    {'key': 'pickup_completed', 'label': 'Pickup Completed'},
    {'key': 'processing', 'label': 'Processing'},
    {'key': 'washing', 'label': 'Washing'},
    {'key': 'drying', 'label': 'Drying'},
    {'key': 'ironing', 'label': 'Steam Ironing'},
    {'key': 'quality_check', 'label': 'Quality Check'},
    {'key': 'ready_for_delivery', 'label': 'Ready for Delivery'},
    {'key': 'out_for_delivery', 'label': 'Out for Delivery'},
    {'key': 'delivered', 'label': 'Delivered'}
  ];

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchOrders();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiService().getStats();
      setState(() {
        _stats = res.data as Map<String, dynamic>;
      });
    } catch (_) {}
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final res = await ApiService().getOrders(); // Admin sees all
      final list = res.data as List;
      setState(() {
        _orders = list.map((o) => Order.fromJson(o as Map<String, dynamic>)).toList();
      });
    } catch (_) {} finally {
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _handleUpdateStatus(int orderId, String status) async {
    try {
      await ApiService().updateOrderStatus(orderId, status);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      _fetchStats();
      _fetchOrders();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }

  Future<void> _handleUpdatePayment(int orderId, String paymentStatus) async {
    try {
      await ApiService().updateOrderPaymentStatus(orderId, paymentStatus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment status updated')));
      _fetchStats();
      _fetchOrders();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update payment status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    final filteredOrders = _orders.where((o) {
      final matchesSearch = o.id.toString().contains(_searchText) ||
          o.userName.toLowerCase().contains(_searchText.toLowerCase()) ||
          o.userPhone.contains(_searchText);
      final matchesStatus = _statusFilter == 'all' || o.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.red),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF021024)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(backgroundColor: Color(0xFF7DA0CA), child: Icon(LucideIcons.shieldCheck, color: Color(0xFF021024))),
                  const SizedBox(height: 12),
                  const Text('LaundryIndia Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(auth.user?.phone ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.activity),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(LucideIcons.indianRupee),
              title: const Text('Rates Config'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/pricing');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.tag),
              title: const Text('Discount Coupons'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/coupons');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary row (horizontal scroll on mobile)
            const Text('Operations Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard('TODAY\'S ORDERS', '${_stats['todayOrders'] ?? 0}', Colors.blue, theme),
                  _buildStatCard('TODAY\'S REVENUE', '₹${_stats['todayRevenue'] ?? '0.00'}', Colors.green, theme),
                  _buildStatCard('PENDING QUEUE', '${_stats['pendingOrders'] ?? 0}', Colors.orange, theme),
                  _buildStatCard('TOTAL CUSTOMERS', '${_stats['totalCustomers'] ?? 0}', Colors.indigo, theme),
                  _buildStatCard('AVG ORDER VALUE', '₹${double.tryParse(_stats['averageOrderValue']?.toString() ?? '0')?.toStringAsFixed(0) ?? 0}', Colors.purple, theme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search filter row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      hintText: 'ID, Customer, Phone',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchText = val),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 12))),
                    ...lifecycleStatuses.map((s) => DropdownMenuItem(value: s['key'], child: Text(s['label']!, style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bookings Directory
            const Text('Customer Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            _isLoadingOrders
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, idx) {
                      final o = filteredOrders[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                  Text('₹${o.grandTotal}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const Divider(),
                              Text('Customer: ${o.userName} (${o.userPhone})', style: const TextStyle(fontSize: 11)),
                              Text('Pickup: ${o.pickupDate} Slot: ${o.pickupTimeSlot}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 8),
                              
                              // Select Status
                              DropdownButtonFormField<String>(
                                value: o.status,
                                decoration: const InputDecoration(labelText: 'Lifecycle Status', contentPadding: EdgeInsets.symmetric(vertical: 0)),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                items: lifecycleStatuses
                                    .map((s) => DropdownMenuItem(value: s['key'], child: Text(s['label']!)))
                                    .toList(),
                                onChanged: (val) => _handleUpdateStatus(o.id, val!),
                              ),
                              const SizedBox(height: 6),
                              
                              // Select Payment Status
                              DropdownButtonFormField<String>(
                                value: o.paymentStatus,
                                decoration: const InputDecoration(labelText: 'Payment Status', contentPadding: EdgeInsets.symmetric(vertical: 0)),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                items: ['pending', 'paid', 'failed', 'refunded']
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                                    .toList(),
                                onChanged: (val) => _handleUpdatePayment(o.id, val!),
                              ),
                              const SizedBox(height: 10),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/track/${o.id}'),
                                    icon: const Icon(LucideIcons.eye, size: 14),
                                    label: const Text('View Tracking logs', style: TextStyle(fontSize: 11)),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, ThemeData theme) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
