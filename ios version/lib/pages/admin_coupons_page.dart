import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/platform_utils.dart';

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
  final _minCartController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  String _discountType = 'flat';
  bool _isSaving = false;

  @override
  void initState() { super.initState(); _fetchCoupons(); }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minCartController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoupons() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getCoupons();
      setState(() { _coupons = res.data as List; });
    } catch (_) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    PlatformUtils.hapticMedium();
    setState(() => _isSaving = true);
    try {
      await ApiService().createCoupon({
        'code': _codeController.text.trim().toUpperCase(),
        'discount_type': _discountType,
        'discount_value': double.tryParse(_valueController.text.trim()) ?? 0.0,
        'min_cart_value': double.tryParse(_minCartController.text.trim()) ?? 0.0,
        'max_discount_value': double.tryParse(_maxDiscountController.text.trim()) ?? 0.0,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
      });
      if (!mounted) return;
      PlatformUtils.hapticSuccess();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon created successfully')));
      _fetchCoupons();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create coupon')));
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _handleToggle(int id) async {
    PlatformUtils.hapticLight();
    try {
      await ApiService().toggleCouponStatus(id);
      _fetchCoupons();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to toggle status')));
    }
  }

  void _showAddSheet() {
    _codeController.clear();
    _valueController.clear();
    _minCartController.clear();
    _maxDiscountController.clear();
    _discountType = 'flat';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Add Discount Coupon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(ctx), child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'Coupon Code (e.g. WELCOME50)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _discountType,
                    decoration: const InputDecoration(labelText: 'Discount Type'),
                    items: const [
                      DropdownMenuItem(value: 'flat', child: Text('Flat Cash (₹)')),
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                    ],
                    onChanged: (val) => setS(() => _discountType = val!),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    decoration: const InputDecoration(labelText: 'Discount Value'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _minCartController,
                    decoration: const InputDecoration(labelText: 'Min Cart Value (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _maxDiscountController,
                    decoration: const InputDecoration(labelText: 'Max Discount Cap (Optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text('Create Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Coupons'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, color: theme.colorScheme.primary),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: _showAddSheet,
            child: Icon(CupertinoIcons.add_circled, color: theme.colorScheme.primary, size: 24),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _coupons.isEmpty
              ? const Center(child: Text('No coupons yet. Tap + to add one.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  physics: PlatformUtils.scrollPhysics,
                  padding: const EdgeInsets.all(16),
                  itemCount: _coupons.length,
                  itemBuilder: (context, idx) {
                    final c = _coupons[idx];
                    final active = c['status'] == 'active';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(c['code'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary, letterSpacing: 1)),
                        subtitle: Text(
                          'Type: ${(c['discount_type'] as String).toUpperCase()} • Value: ${c['discount_value']}\nMin Cart: ₹${c['min_cart_value']}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: CupertinoSwitch(
                          value: active,
                          activeColor: Colors.green,
                          onChanged: (_) => _handleToggle(c['id'] as int),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
