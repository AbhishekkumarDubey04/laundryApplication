import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/cart_provider.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class BookingFlowPage extends StatefulWidget {
  final VoidCallback? onClose;
  const BookingFlowPage({super.key, this.onClose});

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  int _currentStep = 0;
  List<Service> _services = [];
  List<Address> _addresses = [];
  bool _isLoadingCatalog = true;
  bool _isLoadingAddresses = true;

  final _couponController = TextEditingController();
  bool _isValidatingCoupon = false;

  final _addressFormKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _addressTag = 'Home';

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final res = await ApiService().getServices();
      final list = res.data as List;
      setState(() {
        _services = list.map((s) => Service.fromJson(s as Map<String, dynamic>)).toList();
      });
    } catch (_) {} finally {
      setState(() => _isLoadingCatalog = false);
    }
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final res = await ApiService().getAddresses();
      final list = res.data as List;
      setState(() {
        _addresses = list.map((a) => Address.fromJson(a as Map<String, dynamic>)).toList();
      });
    } catch (_) {} finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  List<Map<String, String>> _getNext7Days() {
    final List<Map<String, String>> days = [];
    final now = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final d = now.add(Duration(days: i));
      days.add({
        'value': DateFormat('yyyy-MM-dd').format(d),
        'label': DateFormat('EEE, d MMM').format(d),
      });
    }
    return days;
  }

  Future<void> _applyCouponCode(CartProvider cart) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    try {
      final res = await ApiService().validateCoupon(code, cart.getSubtotal());
      final coupon = Coupon.fromJson(res.data as Map<String, dynamic>);
      cart.setCoupon(coupon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon $code applied! Saved ₹${coupon.discountAmount.toStringAsFixed(0)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid coupon code')));
      cart.setCoupon(null);
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  Future<void> _addNewAddress(CartProvider cart) async {
    if (!_addressFormKey.currentState!.validate()) return;
    final payload = {
      'tag': _addressTag,
      'address_line_1': _addressLine1Controller.text.trim(),
      'address_line_2': _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'is_default': false,
    };

    try {
      final res = await ApiService().addAddress(payload);
      final newAddr = Address.fromJson(res.data as Map<String, dynamic>);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address added successfully')));
      Navigator.pop(context);
      
      await _fetchAddresses();
      cart.setAddress(newAddr.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add address')));
    }
  }

  void _showAddAddressDialog(CartProvider cart) {
    final theme = Theme.of(context);
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _addressTag = 'Home';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Pickup Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _addressFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _addressTag,
                    decoration: const InputDecoration(labelText: 'Tag'),
                    items: ['Home', 'Work', 'Other']
                        .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => _addressTag = val!),
                  ),
                  TextFormField(
                    controller: _addressLine1Controller,
                    decoration: const InputDecoration(labelText: 'Address Line 1'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _addressLine2Controller,
                    decoration: const InputDecoration(labelText: 'Address Line 2 (Optional)'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) => v!.length != 6 ? 'Pincode must be 6 digits' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => _addNewAddress(cart),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Save Address'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout(CartProvider cart, String method) async {
    try {
      // 1. Create order record on backend
      final orderRes = await ApiService().createOrder({
        'pickup_address_id': cart.pickupAddressId,
        'pickup_date': cart.pickupDate,
        'pickup_time_slot': cart.pickupTimeSlot,
        'delivery_preference': cart.deliveryPreference,
        'coupon_code': cart.coupon?.code,
        'items': cart.items
            .map((i) => {
                  'item_id': i.itemId,
                  'service_id': i.serviceId,
                  'quantity': i.quantity,
                })
            .toList(),
      });

      final order = Order.fromJson(orderRes.data['order'] as Map<String, dynamic>);

      // 2. Process payments method
      final payRes = await ApiService().createPayment(order.id, method);

      if (!mounted) return;
      if (method == 'cod') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laundry booked successfully! COD selected.')));
        cart.clearCart();
        Navigator.pushNamedAndRemoveUntil(context, '/track/${order.id}', ModalRoute.withName('/dashboard'));
        return;
      }

      // Online pay Razorpay simulation
      final paymentConfig = payRes.data;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Razorpay Sandbox Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount to Pay: ₹${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Simulating sandbox verification sequence... Tapping success confirms your order payment instantly.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(ctx);
                  await ApiService().verifyPayment({
                    'order_id': order.id,
                    'razorpay_order_id': paymentConfig['id'],
                    'razorpay_payment_id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  });
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Payment approved successfully!')));
                  cart.clearCart();
                  Navigator.pushNamedAndRemoveUntil(ctx, '/track/${order.id}', ModalRoute.withName('/dashboard'));
                } catch (_) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Transaction verification failed.')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Simulate Success'),
            )
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to place order.')));
    }
  }

  void _handleNext(CartProvider cart) {
    if (_currentStep == 0 && cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item.')));
      return;
    }
    if (_currentStep == 1 && cart.pickupAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pickup address.')));
      return;
    }
    if (_currentStep == 2 && (cart.pickupDate == null || cart.pickupTimeSlot == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select schedule slot.')));
      return;
    }
    setState(() => _currentStep += 1);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final isDark = Provider.of<AuthProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Booking (Step ${_currentStep + 1} of 4)'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step indicators
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepHeader('Items', 0),
                const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                _buildStepHeader('Address', 1),
                const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                _buildStepHeader('Schedule', 2),
                const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                _buildStepHeader('Checkout', 3),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(cart, theme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, int stepIdx) {
    final active = _currentStep == stepIdx;
    final done = _currentStep > stepIdx;
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: active 
              ? theme.colorScheme.primary 
              : (done ? Colors.green : Colors.grey.shade300),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text('${stepIdx + 1}', style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? theme.colorScheme.primary : Colors.grey)),
      ],
    );
  }

  Widget _buildStepContent(CartProvider cart, ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStepCatalog(cart, theme, isDark);
      case 1:
        return _buildStepAddresses(cart, theme, isDark);
      case 2:
        return _buildStepSchedule(cart, theme, isDark);
      case 3:
        return _buildStepCheckout(cart, theme, isDark);
      default:
        return Container();
    }
  }

  // STEP 1 UI
  Widget _buildStepCatalog(CartProvider cart, ThemeData theme, bool isDark) {
    if (_isLoadingCatalog) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        ..._services.map((service) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...service.items.map((item) {
                      final cartItemIdx = cart.items.indexWhere(
                        (c) => c.serviceId == service.id && c.itemId == item.id,
                      );
                      final qty = cartItemIdx >= 0 ? cart.items[cartItemIdx].quantity : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            qty > 0
                                ? Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () => cart.updateQuantity(service.id, item.id, qty - 1),
                                      ),
                                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () => cart.updateQuantity(service.id, item.id, qty + 1),
                                      ),
                                    ],
                                  )
                                : ElevatedButton(
                                    onPressed: () => cart.addItem(
                                      LocalCartItem(
                                        serviceId: service.id,
                                        serviceName: service.name,
                                        itemId: item.id,
                                        itemName: item.name,
                                        price: item.price,
                                        category: item.category,
                                        quantity: 1,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: const Text('Add'),
                                  )
                          ],
                        ),
                      );
                    })
                  ],
                ),
              ),
            )),
        if (cart.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.primary.withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cart.totalItemCount} Items Added', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Subtotal: ₹${cart.getSubtotal().toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _handleNext(cart),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                    child: const Row(
                      children: [
                        Text('Address '),
                        Icon(LucideIcons.chevronRight, size: 14),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ]
      ],
    );
  }

  // STEP 2 UI
  Widget _buildStepAddresses(CartProvider cart, ThemeData theme, bool isDark) {
    if (_isLoadingAddresses) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('Select Pickup Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 16),
        ..._addresses.map((addr) {
          final selected = cart.pickupAddressId == addr.id;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: selected ? Colors.blue : Colors.transparent, width: 2),
            ),
            child: InkWell(
              onTap: () => cart.setAddress(addr.id),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(LucideIcons.mapPin, color: selected ? Colors.blue : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addr.tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(addr.addressLine1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('${addr.city}, ${addr.state} - ${addr.pincode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _showAddAddressDialog(cart),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Create New Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: cart.pickupAddressId == null ? null : () => _handleNext(cart),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Schedule Slots'),
            ),
          ],
        )
      ],
    );
  }

  // STEP 3 UI
  Widget _buildStepSchedule(CartProvider cart, ThemeData theme, bool isDark) {
    final next7Days = _getNext7Days();
    final List<String> timeSlots = ['9-11 AM', '11-1 PM', '1-3 PM', '3-5 PM', '5-7 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('Select Schedule Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 16),
        
        // Date Selector
        const Text('1. Pickup Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: next7Days.length,
            itemBuilder: (context, idx) {
              final day = next7Days[idx];
              final selected = cart.pickupDate == day['value'];
              return GestureDetector(
                onTap: () => cart.setSchedule(day['value']!, cart.pickupTimeSlot ?? ''),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary.withOpacity(0.15) : theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? Colors.orange : Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(day['label']!.split(',')[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(day['label']!.split(',')[1], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Time Slot Selector
        const Text('2. Pickup Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            final selected = cart.pickupTimeSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: selected,
              onSelected: (val) {
                if (val) cart.setSchedule(cart.pickupDate ?? '', slot);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Delivery speed selector
        const Text('3. Delivery Speed Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('Standard Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Takes 3 days. Base delivery charge applies (₹30 or free).', style: TextStyle(fontSize: 11, color: Colors.grey)),
          value: 'standard',
          groupValue: cart.deliveryPreference,
          onChanged: (val) => cart.setDeliveryPreference(val!),
        ),
        RadioListTile<String>(
          title: const Text('Express Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Returned in 24 hours. Extra ₹50 applies.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          value: 'express',
          groupValue: cart.deliveryPreference,
          onChanged: (val) => cart.setDeliveryPreference(val!),
        ),
        RadioListTile<String>(
          title: const Text('Same Day Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Collection before 11 AM, returned tonight (+₹100).', style: TextStyle(fontSize: 11, color: Colors.grey)),
          value: 'same_day',
          groupValue: cart.deliveryPreference,
          onChanged: (val) => cart.setDeliveryPreference(val!),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: (cart.pickupDate == null || cart.pickupTimeSlot == null)
                  ? null
                  : () => _handleNext(cart),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Review Invoice'),
            ),
          ],
        )
      ],
    );
  }

  // STEP 4 UI
  Widget _buildStepCheckout(CartProvider cart, ThemeData theme, bool isDark) {
    final activeAddress = _addresses.firstWhere((a) => a.id == cart.pickupAddressId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('Review & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 16),

        // Garment details list
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Garment Basket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Divider(),
                ...cart.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i.itemName} × ${i.quantity} (${i.serviceName})', style: const TextStyle(fontSize: 11)),
                          Text('₹${(i.price * i.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Schedule and address details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pickup Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scheduled Date:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(cart.pickupDate ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time Slot:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(cart.pickupTimeSlot ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Mode:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(cart.deliveryPreference.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Address:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('${activeAddress.addressLine1}, ${activeAddress.city} - ${activeAddress.pincode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Invoice price details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Divider(),
                
                // Coupon input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: const InputDecoration(hintText: 'e.g. WELCOME50', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        enabled: cart.coupon == null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    cart.coupon == null
                        ? ElevatedButton(
                            onPressed: _isValidatingCoupon ? null : () => _applyCouponCode(cart),
                            child: _isValidatingCoupon ? const CircularProgressIndicator() : const Text('Apply'),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              cart.setCoupon(null);
                              _couponController.clear();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Remove'),
                          ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInvoiceRow('Items Subtotal:', '₹${cart.getSubtotal().toStringAsFixed(2)}'),
                if (cart.coupon != null)
                  _buildInvoiceRow('Coupon Discount:', '- ₹${cart.getDiscountAmount().toStringAsFixed(2)}', Colors.green),
                _buildInvoiceRow('Delivery Charges:', '₹${cart.getDeliveryCharges().toStringAsFixed(2)}'),
                _buildInvoiceRow('GST Tax (18%):', '₹${cart.getTax().toStringAsFixed(2)}'),
                const Divider(),
                _buildInvoiceRow(
                  'Grand Total:',
                  '₹${cart.getGrandTotal().toStringAsFixed(2)}',
                  const Color(0xFF021024),
                  true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action pay buttons
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => _handleCheckout(cart, 'razorpay'),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
            child: const Text('Pay Securely Online'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleCheckout(cart, 'cod'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInvoiceRow(String label, String val, [Color? color, bool isTotal = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: isTotal ? 14 : 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
