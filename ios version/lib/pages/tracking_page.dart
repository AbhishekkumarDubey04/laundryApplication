import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';

class TrackingPage extends StatefulWidget {
  final int orderId;
  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  Order? _order;
  List<OrderItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<Map<String, String>> lifecycleStatuses = [
    {'key': 'created', 'label': 'Order Created', 'desc': 'Order submitted to the queue.'},
    {'key': 'pickup_scheduled', 'label': 'Pickup Scheduled', 'desc': 'Agent assigned to collect clothes.'},
    {'key': 'pickup_completed', 'label': 'Pickup Completed', 'desc': 'Clothes collected by our agent.'},
    {'key': 'processing', 'label': 'Processing', 'desc': 'Garments sorted and inspected.'},
    {'key': 'washing', 'label': 'Washing', 'desc': 'Garments washing cycles in progress.'},
    {'key': 'drying', 'label': 'Drying', 'desc': 'Machine drying and sorting.'},
    {'key': 'ironing', 'label': 'Steam Ironing', 'desc': 'Creaseless steam pressing.'},
    {'key': 'quality_check', 'label': 'Quality Check', 'desc': 'Post-press standard review.'},
    {'key': 'ready_for_delivery', 'label': 'Ready for Delivery', 'desc': 'Packed and ready at hub.'},
    {'key': 'out_for_delivery', 'label': 'Out for Delivery', 'desc': 'Delivery agent is on the way.'},
    {'key': 'delivered', 'label': 'Delivered', 'desc': 'Clothes handed over to customer.'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ApiService().getOrderById(widget.orderId);
      final data = res.data;
      final o = Order.fromJson(data['order'] as Map<String, dynamic>);
      final itemsRaw = data['items'] as List? ?? [];
      final list = itemsRaw.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList();
      setState(() { _order = o; _items = list; });
    } catch (e) {
      setState(() { _errorMessage = 'Failed to load tracking details.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleUpdateStatus(String status) async {
    PlatformUtils.hapticMedium();
    try {
      await ApiService().updateOrderStatus(widget.orderId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      _fetchDetails();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }

  Future<void> _handleUpdatePayment(String paymentStatus) async {
    PlatformUtils.hapticMedium();
    try {
      await ApiService().updateOrderPaymentStatus(widget.orderId, paymentStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment status updated')));
      _fetchDetails();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update payment')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Order #${widget.orderId}')),
        body: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Order #${widget.orderId}')),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Order not found', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CupertinoButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ]),
        ),
      );
    }

    final activeIndex = lifecycleStatuses.indexWhere((s) => s['key'] == _order!.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, color: theme.colorScheme.primary),
        ),
      ),
      body: CustomScrollView(
        physics: PlatformUtils.scrollPhysics,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Admin override controls
                if (auth.isAdmin) ...[
                  _buildAdminControlsCard(theme),
                  const SizedBox(height: 16),
                ],

                // Timeline tracker
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Order Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _order!.status.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ),
                        ]),
                        const Divider(),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lifecycleStatuses.length,
                          itemBuilder: (context, idx) {
                            final s = lifecycleStatuses[idx];
                            final isDone = idx < activeIndex;
                            final isActive = idx == activeIndex;
                            return _buildTimelineStep(s['label']!, s['desc']!, isDone, isActive, idx == lifecycleStatuses.length - 1, theme);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoice details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Divider(),
                        _info('Customer:', _order!.userName),
                        _info('Mobile:', _order!.userPhone),
                        _info('Est. Delivery:', _order!.deliveryDate),
                        const SizedBox(height: 12),
                        const Text('Garment Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ..._items.map((i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text('${i.itemName} × ${i.quantity} (${i.serviceName})', style: const TextStyle(fontSize: 11))),
                            Text('₹${i.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ]),
                        )),
                        const Divider(),
                        _info('Subtotal:', '₹${_order!.totalAmount.toStringAsFixed(2)}'),
                        if (_order!.discountAmount > 0)
                          _info('Discount:', '- ₹${_order!.discountAmount.toStringAsFixed(2)}', Colors.green),
                        _info('Delivery:', '₹${_order!.deliveryCharges.toStringAsFixed(2)}'),
                        _info('GST (18%):', '₹${_order!.taxAmount.toStringAsFixed(2)}'),
                        const Divider(),
                        _info('Grand Total:', '₹${_order!.grandTotal.toStringAsFixed(2)}', theme.colorScheme.primary, true),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Payment:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _order!.paymentStatus == 'paid' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _order!.paymentStatus.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _order!.paymentStatus == 'paid' ? Colors.green : Colors.orange),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, String desc, bool isDone, bool isActive, bool isLast, ThemeData theme) {
    Color indicatorColor = Colors.grey.shade300;
    if (isDone) indicatorColor = Colors.green;
    if (isActive) indicatorColor = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          CircleAvatar(
            radius: 7,
            backgroundColor: indicatorColor,
            child: isDone ? const Icon(Icons.check, size: 9, color: Colors.white) : null,
          ),
          if (!isLast) Container(width: 2, height: 42, color: isDone ? Colors.green : Colors.grey.shade200),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? theme.colorScheme.primary : (isDone ? Colors.green : Colors.grey))),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 10),
          ]),
        ),
      ],
    );
  }

  Widget _info(String label, String val, [Color? color, bool isTotal = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, color: isTotal ? null : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildAdminControlsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(LucideIcons.shieldCheck, color: Colors.orangeAccent, size: 18),
              SizedBox(width: 8),
              Text('Admin Override', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orangeAccent)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _order!.status,
              decoration: const InputDecoration(labelText: 'Lifecycle Status', isDense: true),
              items: lifecycleStatuses.map((s) => DropdownMenuItem(value: s['key'], child: Text(s['label']!, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => _handleUpdateStatus(val!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _order!.paymentStatus,
              decoration: const InputDecoration(labelText: 'Payment Status', isDense: true),
              items: ['pending', 'paid', 'failed', 'refunded'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => _handleUpdatePayment(val!),
            ),
          ],
        ),
      ),
    );
  }
}
