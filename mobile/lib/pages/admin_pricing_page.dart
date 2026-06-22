import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/models.dart';

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
  void initState() {
    super.initState();
    _fetchPricing();
    _fetchDropdownOptions();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchPricing() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getPricingCatalog();
      final list = res.data as List;
      setState(() {
        _pricing = list.map((p) => PricingRow.fromJson(p as Map<String, dynamic>)).toList();
      });
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      final servicesRes = await ApiService().getServices();
      final servicesList = servicesRes.data as List;
      
      final itemsRes = await ApiService().getCatalogItems();
      final itemsList = itemsRes.data as List;
      
      setState(() {
        _services = servicesList.map((s) => Service.fromJson(s as Map<String, dynamic>)).toList();
        _items = itemsList.map((i) => ServiceItem.fromJson(i as Map<String, dynamic>)).toList();
      });
    } catch (_) {}
  }

  Future<void> _handleSavePricing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      'service_id': _selectedServiceId,
      'item_id': _selectedItemId,
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
    };

    try {
      await ApiService().addPricingRate(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rates configuration updated')));
      Navigator.pop(context);
      _fetchPricing();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to configure rate')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeletePricing(int id) async {
    try {
      await ApiService().deletePricingRate(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing rate removed')));
      _fetchPricing();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove rate')));
    }
  }

  void _showAddPricingDialog() {
    _priceController.clear();
    _selectedServiceId = _services.isNotEmpty ? _services.first.id : null;
    _selectedItemId = _items.isNotEmpty ? _items.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Configure Pricing Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedServiceId,
                    decoration: const InputDecoration(labelText: 'Laundry Service'),
                    items: _services
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) => setDialogState(() => _selectedServiceId = val),
                  ),
                  DropdownButtonFormField<int>(
                    value: _selectedItemId,
                    decoration: const InputDecoration(labelText: 'Clothing Item'),
                    items: _items
                        .map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.category})', style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) => setDialogState(() => _selectedItemId = val),
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price Rate (INR)', prefixText: '₹ '),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSavePricing,
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Save Config'),
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
        title: const Text('Rates Configuration'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _showAddPricingDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _pricing.length,
              itemBuilder: (context, idx) {
                final p = _pricing[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(p.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Service: ${p.serviceName}\nCategory: ${p.itemCategory}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                content: const Text('Are you sure you want to remove this pricing configuration?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _handleDeletePricing(p.id);
                                    },
                                    child: const Text('Yes', style: TextStyle(color: Colors.red)),
                                  )
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
