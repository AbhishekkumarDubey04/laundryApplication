import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';

class AdminPricingPage extends StatefulWidget {
  const AdminPricingPage({super.key});
  @override
  State<AdminPricingPage> createState() => _AdminPricingPageState();
}

class _AdminPricingPageState extends State<AdminPricingPage> {
  List<PricingRow> _pricing = [];
  List<Service> _services = [];
  List<ServiceItem> _items = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  int? _selectedServiceId;
  int? _selectedItemId;
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() { super.initState(); _fetchPricing(); _fetchDropdowns(); }

  @override
  void dispose() { _priceController.dispose(); super.dispose(); }

  Future<void> _fetchPricing() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getPricingCatalog();
      final list = res.data as List;
      setState(() { _pricing = list.map((p) => PricingRow.fromJson(p as Map<String, dynamic>)).toList(); });
    } catch (_) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _fetchDropdowns() async {
    try {
      final sRes = await ApiService().getServices();
      final iRes = await ApiService().getCatalogItems();
      setState(() {
        _services = (sRes.data as List).map((s) => Service.fromJson(s as Map<String, dynamic>)).toList();
        _items = (iRes.data as List).map((i) => ServiceItem.fromJson(i as Map<String, dynamic>)).toList();
        _selectedServiceId = _services.isNotEmpty ? _services.first.id : null;
        _selectedItemId = _items.isNotEmpty ? _items.first.id : null;
      });
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    PlatformUtils.hapticMedium();
    setState(() => _isSaving = true);
    try {
      await ApiService().addPricingRate({
        'service_id': _selectedServiceId,
        'item_id': _selectedItemId,
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      });
      if (!mounted) return;
      PlatformUtils.hapticSuccess();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing rate saved')));
      _fetchPricing();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save rate')));
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _handleDelete(int id) async {
    PlatformUtils.hapticMedium();
    try {
      await ApiService().deletePricingRate(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate deleted')));
      _fetchPricing();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
    }
  }

  void _showAddSheet() {
    _priceController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configure Pricing Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedServiceId,
                  decoration: const InputDecoration(labelText: 'Laundry Service'),
                  items: _services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setS(() => _selectedServiceId = val),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedItemId,
                  decoration: const InputDecoration(labelText: 'Clothing Item'),
                  items: _items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.category})', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setS(() => _selectedItemId = val),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price (INR)', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
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
                        : const Text('Save Rate', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rates Configuration'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: _showAddSheet,
            child: Icon(CupertinoIcons.add_circled, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView.builder(
              physics: PlatformUtils.scrollPhysics,
              padding: const EdgeInsets.all(16),
              itemCount: _pricing.length,
              itemBuilder: (context, idx) {
                final p = _pricing[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(p.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${p.serviceName} • ${p.itemCategory}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                      CupertinoButton(
                        padding: const EdgeInsets.only(left: 8),
                        onPressed: () => PlatformUtils.showAdaptiveDialog(
                          context: context,
                          title: 'Delete Rate',
                          content: 'Remove pricing for ${p.itemName}?',
                          confirmLabel: 'Delete',
                          cancelLabel: 'Cancel',
                          destructive: true,
                          onConfirm: () => _handleDelete(p.id),
                        ),
                        child: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
