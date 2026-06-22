import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';

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
    {'key': 'delivered', 'label': 'Delivered'},
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
      setState(() { _stats = res.data as Map<String, dynamic>; });
    } catch (_) {}
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final res = await ApiService().getOrders();
      final list = res.data as List;
      setState(() { _orders = list.map((o) => Order.fromJson(o as Map<String, dynamic>)).toList(); });
    } catch (_) {} finally {
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _handleUpdateStatus(int orderId, String status) async {
    PlatformUtils.hapticMedium();
    try {
      await ApiService().updateOrderStatus(orderId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      _fetchStats(); _fetchOrders();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }

  Future<void> _handleUpdatePayment(int orderId, String paymentStatus) async {
    PlatformUtils.hapticMedium();
    try {
      await ApiService().updateOrderPaymentStatus(orderId, paymentStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment updated')));
      _fetchStats(); _fetchOrders();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update payment')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    final filteredOrders = _orders.where((o) {
      final matchSearch = o.id.toString().contains(_searchText) ||
          o.userName.toLowerCase().contains(_searchText.toLowerCase()) ||
          o.userPhone.contains(_searchText);
      final matchStatus = _statusFilter == 'all' || o.status == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () { PlatformUtils.hapticLight(); auth.toggleTheme(); },
            child: Icon(auth.isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon, size: 20, color: theme.colorScheme.primary),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: () async {
              PlatformUtils.hapticMedium();
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Icon(CupertinoIcons.square_arrow_right, color: Colors.red, size: 22),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(backgroundColor: Colors.white, child: Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary)),
              const SizedBox(height: 12),
              const Text('LaundryIndia Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(auth.user?.phone ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          ListTile(leading: const Icon(LucideIcons.activity), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(LucideIcons.indianRupee),
            title: const Text('Rates Config'),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/admin/pricing'); },
          ),
          ListTile(
            leading: const Icon(LucideIcons.tag),
            title: const Text('Discount Coupons'),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/admin/coupons'); },
          ),
        ]),
      ),
      body: CustomScrollView(
        physics: PlatformUtils.scrollPhysics,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI Cards
                const Text('Operations Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: PlatformUtils.scrollPhysics,
                    children: [
                      _statCard("TODAY'S ORDERS", '${_stats['todayOrders'] ?? 0}', Colors.blue),
                      _statCard("TODAY'S REVENUE", '₹${_stats['todayRevenue'] ?? '0'}', Colors.green),
                      _statCard('PENDING QUEUE', '${_stats['pendingOrders'] ?? 0}', Colors.orange),
                      _statCard('TOTAL CUSTOMERS', '${_stats['totalCustomers'] ?? 0}', Colors.indigo),
                      _statCard('AVG ORDER', '₹${double.tryParse(_stats['averageOrderValue']?.toString() ?? '0')?.toStringAsFixed(0) ?? 0}', Colors.purple),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search + Filter
                Row(children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        hintText: 'ID, Customer, Phone',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) => setState(() => _searchText = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _statusFilter,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 12))),
                      ...lifecycleStatuses.map((s) => DropdownMenuItem(value: s['key'], child: Text(s['label']!, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val!),
                  ),
                ]),
                const SizedBox(height: 16),

                // Orders
                const Text('Customer Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _isLoadingOrders
                    ? const Center(child: CupertinoActivityIndicator())
                    : filteredOrders.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No orders found', style: TextStyle(color: Colors.grey))))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, idx) {
                              final o = filteredOrders[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                        Text('₹${o.grandTotal}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ]),
                                      const Divider(),
                                      Text('${o.userName} • ${o.userPhone}', style: const TextStyle(fontSize: 11)),
                                      Text('Pickup: ${o.pickupDate} @ ${o.pickupTimeSlot}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: o.status,
                                        decoration: const InputDecoration(labelText: 'Lifecycle Status', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        items: lifecycleStatuses.map((s) => DropdownMenuItem(value: s['key'], child: Text(s['label']!))).toList(),
                                        onChanged: (val) => _handleUpdateStatus(o.id, val!),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: o.paymentStatus,
                                        decoration: const InputDecoration(labelText: 'Payment Status', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        items: ['pending', 'paid', 'failed', 'refunded'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                                        onChanged: (val) => _handleUpdatePayment(o.id, val!),
                                      ),
                                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                        CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () { PlatformUtils.hapticLight(); Navigator.pushNamed(context, '/track/${o.id}'); },
                                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                            Icon(CupertinoIcons.eye, size: 14),
                                            SizedBox(width: 4),
                                            Text('View Tracking', style: TextStyle(fontSize: 11)),
                                          ]),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}
