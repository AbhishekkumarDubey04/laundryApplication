import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  List<dynamic> _coupons = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _minCartValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  String _discountType = 'flat';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minCartValueController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoupons() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getCoupons();
      setState(() {
        _coupons = res.data as List;
      });
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSaveCoupon() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      'code': _codeController.text.trim().toUpperCase(),
      'discount_type': _discountType,
      'discount_value': double.tryParse(_valueController.text.trim()) ?? 0.0,
      'min_cart_value': double.tryParse(_minCartValueController.text.trim()) ?? 0.0,
      'max_discount_value': double.tryParse(_maxDiscountController.text.trim()) ?? 0.0,
      'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
    };

    try {
      await ApiService().createCoupon(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon added successfully')));
      Navigator.pop(context);
      _fetchCoupons();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add coupon')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleToggleStatus(int id) async {
    try {
      await ApiService().toggleCouponStatus(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon status toggled')));
      _fetchCoupons();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to toggle status')));
    }
  }

  void _showAddCouponDialog() {
    _codeController.clear();
    _valueController.clear();
    _minCartValueController.clear();
    _maxDiscountController.clear();
    _discountType = 'flat';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Discount Coupon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'Coupon Code'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _discountType,
                    decoration: const InputDecoration(labelText: 'Discount Type'),
                    items: const [
                      DropdownMenuItem(value: 'flat', child: Text('Flat Cash Discount (INR)')),
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount (%)')),
                    ],
                    onChanged: (val) => setDialogState(() => _discountType = val!),
                  ),
                  TextFormField(
                    controller: _valueController,
                    decoration: const InputDecoration(labelText: 'Discount Value'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _minCartValueController,
                    decoration: const InputDecoration(labelText: 'Min Cart Subtotal (INR)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _maxDiscountController,
                    decoration: const InputDecoration(labelText: 'Max Discount limit (Optional)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSaveCoupon,
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Save Coupon'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Coupons'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _showAddCouponDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _coupons.length,
              itemBuilder: (context, idx) {
                final c = _coupons[idx];
                final active = c['status'] == 'active';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(c['code'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                    subtitle: Text(
                      'Type: ${(c['discount_type'] as String).toUpperCase()}\nValue: ${c['discount_value']} • Min Cart: ₹${c['min_cart_value']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: Switch(
                      value: active,
                      activeColor: Colors.green,
                      onChanged: (_) => _handleToggleStatus(c['id'] as int),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
