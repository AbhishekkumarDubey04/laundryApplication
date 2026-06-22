import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/cart_provider.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';
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
    PlatformUtils.hapticMedium();
    setState(() => _isValidatingCoupon = true);
    try {
      final res = await ApiService().validateCoupon(code, cart.getSubtotal());
      final coupon = Coupon.fromJson(res.data as Map<String, dynamic>);
      cart.setCoupon(coupon);
      if (!mounted) return;
      PlatformUtils.hapticSuccess();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Coupon $code applied! Saved ₹${coupon.discountAmount.toStringAsFixed(0)}')));
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
    PlatformUtils.hapticMedium();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address added')));
      Navigator.pop(context);
      await _fetchAddresses();
      cart.setAddress(newAddr.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add address')));
    }
  }

  void _showAddAddressSheet(CartProvider cart) {
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _addressTag = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: _addressFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Pickup Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _addressTag,
                    decoration: const InputDecoration(labelText: 'Tag'),
                    items: ['Home', 'Work', 'Other'].map((tag) => DropdownMenuItem(value: tag, child: Text(tag))).toList(),
                    onChanged: (val) => setS(() => _addressTag = val!),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(controller: _addressLine1Controller, decoration: const InputDecoration(labelText: 'Address Line 1'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 8),
                  TextFormField(controller: _addressLine2Controller, decoration: const InputDecoration(labelText: 'Address Line 2 (Optional)')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                  ]),
                  const SizedBox(height: 8),
                  TextFormField(controller: _pincodeController, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number, maxLength: 6, validator: (v) => v!.length != 6 ? '6 digits required' : null),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () => _addNewAddress(cart),
                      child: const Text('Save Address', style: TextStyle(color: Colors.white)),
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

  Future<void> _handleCheckout(CartProvider cart, String method) async {
    PlatformUtils.hapticHeavy();
    try {
      final orderRes = await ApiService().createOrder({
        'pickup_address_id': cart.pickupAddressId,
        'pickup_date': cart.pickupDate,
        'pickup_time_slot': cart.pickupTimeSlot,
        'delivery_preference': cart.deliveryPreference,
        'coupon_code': cart.coupon?.code,
        'items': cart.items.map((i) => {'item_id': i.itemId, 'service_id': i.serviceId, 'quantity': i.quantity}).toList(),
      });
      final order = Order.fromJson(orderRes.data['order'] as Map<String, dynamic>);
      final payRes = await ApiService().createPayment(order.id, method);

      if (!mounted) return;
      if (method == 'cod') {
        PlatformUtils.hapticSuccess();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laundry booked! COD selected.')));
        cart.clearCart();
        Navigator.pushNamedAndRemoveUntil(context, '/track/${order.id}', ModalRoute.withName('/dashboard'));
        return;
      }

      final paymentConfig = payRes.data;
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Razorpay Sandbox Payment'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              Text('Amount: ₹${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tap Simulate Success to confirm your payment instantly.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                try {
                  Navigator.pop(ctx);
                  await ApiService().verifyPayment({
                    'order_id': order.id,
                    'razorpay_order_id': paymentConfig['id'],
                    'razorpay_payment_id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  });
                  if (!mounted) return;
                  PlatformUtils.hapticSuccess();
                  cart.clearCart();
                  Navigator.pushNamedAndRemoveUntil(context, '/track/${order.id}', ModalRoute.withName('/dashboard'));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verification failed.')));
                }
              },
              child: const Text('Simulate Success'),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a schedule slot.')));
      return;
    }
    PlatformUtils.hapticMedium();
    setState(() => _currentStep += 1);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final isDark = Provider.of<AuthProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking (Step ${_currentStep + 1} of 4)'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (_currentStep > 0) {
              PlatformUtils.hapticLight();
              setState(() => _currentStep -= 1);
            } else {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            }
          },
          child: Icon(CupertinoIcons.back, color: theme.colorScheme.primary),
        ),
      ),
      body: Column(
        children: [
          // Step indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepHeader('Items', 0, theme),
                const Icon(CupertinoIcons.right_chevron, size: 10, color: Colors.grey),
                _buildStepHeader('Address', 1, theme),
                const Icon(CupertinoIcons.right_chevron, size: 10, color: Colors.grey),
                _buildStepHeader('Schedule', 2, theme),
                const Icon(CupertinoIcons.right_chevron, size: 10, color: Colors.grey),
                _buildStepHeader('Checkout', 3, theme),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomScrollView(
              physics: PlatformUtils.scrollPhysics,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [_buildStepContent(cart, theme, isDark)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, int stepIdx, ThemeData theme) {
    final active = _currentStep == stepIdx;
    final done = _currentStep > stepIdx;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: active
              ? theme.colorScheme.primary
              : (done ? Colors.green : Colors.grey.shade300),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text('${stepIdx + 1}',
                  style: TextStyle(
                      fontSize: 10,
                      color: active ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? theme.colorScheme.primary : Colors.grey)),
      ],
    );
  }

  Widget _buildStepContent(CartProvider cart, ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0: return _buildStepCatalog(cart, theme);
      case 1: return _buildStepAddresses(cart, theme);
      case 2: return _buildStepSchedule(cart, theme);
      case 3: return _buildStepCheckout(cart, theme);
      default: return Container();
    }
  }

  Widget _buildStepCatalog(CartProvider cart, ThemeData theme) {
    if (_isLoadingCatalog) return const Center(child: CupertinoActivityIndicator());
    return Column(
      children: [
        ..._services.map((service) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...service.items.map((item) {
                  final cartItemIdx = cart.items.indexWhere((c) => c.serviceId == service.id && c.itemId == item.id);
                  final qty = cartItemIdx >= 0 ? cart.items[cartItemIdx].quantity : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ]),
                        qty > 0
                            ? Row(children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () { PlatformUtils.hapticLight(); cart.updateQuantity(service.id, item.id, qty - 1); },
                                  child: const Icon(CupertinoIcons.minus_circle, size: 28, color: Colors.red),
                                ),
                                Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () { PlatformUtils.hapticLight(); cart.updateQuantity(service.id, item.id, qty + 1); },
                                  child: Icon(CupertinoIcons.plus_circle, size: 28, color: theme.colorScheme.primary),
                                ),
                              ])
                            : CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                                onPressed: () {
                                  PlatformUtils.hapticLight();
                                  cart.addItem(LocalCartItem(serviceId: service.id, serviceName: service.name, itemId: item.id, itemName: item.name, price: item.price, category: item.category, quantity: 1));
                                },
                                child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        )),
        if (cart.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${cart.totalItemCount} Items', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Subtotal: ₹${cart.getSubtotal().toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () => _handleNext(cart),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Address ', style: TextStyle(color: Colors.white)),
                    Icon(CupertinoIcons.right_chevron, size: 14, color: Colors.white),
                  ]),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildStepAddresses(CartProvider cart, ThemeData theme) {
    if (_isLoadingAddresses) return const Center(child: CupertinoActivityIndicator());
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
              side: BorderSide(color: selected ? theme.colorScheme.primary : Colors.transparent, width: 2),
            ),
            child: InkWell(
              onTap: () { PlatformUtils.hapticLight(); cart.setAddress(addr.id); },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(LucideIcons.mapPin, color: selected ? theme.colorScheme.primary : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(addr.tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(addr.addressLine1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('${addr.city}, ${addr.state} - ${addr.pincode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
                  if (selected) Icon(CupertinoIcons.checkmark_circle_fill, color: theme.colorScheme.primary),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          child: InkWell(
            onTap: () => _showAddAddressSheet(cart),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(CupertinoIcons.plus_circle, color: Colors.grey),
                SizedBox(width: 8),
                Text('Create New Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CupertinoButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('Back')),
          CupertinoButton(
            color: cart.pickupAddressId == null ? Colors.grey : theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            onPressed: cart.pickupAddressId == null ? null : () => _handleNext(cart),
            child: const Text('Schedule Slots', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ],
    );
  }

  Widget _buildStepSchedule(CartProvider cart, ThemeData theme) {
    final next7Days = _getNext7Days();
    final timeSlots = ['9-11 AM', '11-1 PM', '1-3 PM', '3-5 PM', '5-7 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('Select Schedule Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 16),
        const Text('1. Pickup Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: PlatformUtils.scrollPhysics,
            itemCount: next7Days.length,
            itemBuilder: (context, idx) {
              final day = next7Days[idx];
              final selected = cart.pickupDate == day['value'];
              return GestureDetector(
                onTap: () { PlatformUtils.hapticLight(); cart.setSchedule(day['value']!, cart.pickupTimeSlot ?? ''); },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary.withOpacity(0.15) : theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? theme.colorScheme.primary : Colors.grey.shade300),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(day['label']!.split(',')[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(day['label']!.split(',')[1], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text('2. Pickup Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            final selected = cart.pickupTimeSlot == slot;
            return GestureDetector(
              onTap: () { PlatformUtils.hapticLight(); cart.setSchedule(cart.pickupDate ?? '', slot); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? theme.colorScheme.primary : Colors.grey.shade300),
                ),
                child: Text(slot, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : null)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('3. Delivery Speed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        _buildDeliveryOption(cart, 'standard', 'Standard (3 days)', 'Base delivery charge (₹30 or free if > ₹500)', theme),
        _buildDeliveryOption(cart, 'express', 'Express (24 hours)', 'Extra ₹50 charge', theme),
        _buildDeliveryOption(cart, 'same_day', 'Same Day', 'Book before 11 AM, collected tonight (+₹100)', theme),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CupertinoButton(onPressed: () => setState(() => _currentStep = 1), child: const Text('Back')),
          CupertinoButton(
            color: (cart.pickupDate == null || cart.pickupTimeSlot == null) ? Colors.grey : theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            onPressed: (cart.pickupDate == null || cart.pickupTimeSlot == null) ? null : () => _handleNext(cart),
            child: const Text('Review Invoice', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ],
    );
  }

  Widget _buildDeliveryOption(CartProvider cart, String value, String title, String subtitle, ThemeData theme) {
    final selected = cart.deliveryPreference == value;
    return GestureDetector(
      onTap: () { PlatformUtils.hapticLight(); cart.setDeliveryPreference(value); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withOpacity(0.08) : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.dividerColor),
        ),
        child: Row(children: [
          Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, color: selected ? theme.colorScheme.primary : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: selected ? theme.colorScheme.primary : null)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildStepCheckout(CartProvider cart, ThemeData theme) {
    final activeAddress = _addresses.firstWhere((a) => a.id == cart.pickupAddressId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('Review & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Garment Basket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Divider(),
              ...cart.items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${i.itemName} × ${i.quantity} (${i.serviceName})', style: const TextStyle(fontSize: 11)),
                  Text('₹${(i.price * i.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pickup Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Divider(),
              _row('Date:', cart.pickupDate ?? ''),
              _row('Time Slot:', cart.pickupTimeSlot ?? ''),
              _row('Delivery:', cart.deliveryPreference.toUpperCase()),
              const SizedBox(height: 4),
              const Text('Address:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('${activeAddress.addressLine1}, ${activeAddress.city} - ${activeAddress.pincode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Coupon Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: const InputDecoration(hintText: 'e.g. WELCOME50'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    enabled: cart.coupon == null,
                  ),
                ),
                const SizedBox(width: 8),
                cart.coupon == null
                    ? CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: _isValidatingCoupon ? null : () => _applyCouponCode(cart),
                        child: _isValidatingCoupon
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : const Text('Apply', style: TextStyle(color: Colors.white)),
                      )
                    : CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () { cart.setCoupon(null); _couponController.clear(); },
                        child: const Text('Remove', style: TextStyle(color: Colors.white)),
                      ),
              ]),
              const SizedBox(height: 16),
              const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Divider(),
              _invoiceRow('Items Subtotal:', '₹${cart.getSubtotal().toStringAsFixed(2)}'),
              if (cart.coupon != null) _invoiceRow('Coupon Discount:', '- ₹${cart.getDiscountAmount().toStringAsFixed(2)}', Colors.green),
              _invoiceRow('Delivery Charges:', '₹${cart.getDeliveryCharges().toStringAsFixed(2)}'),
              _invoiceRow('GST Tax (18%):', '₹${cart.getTax().toStringAsFixed(2)}'),
              const Divider(),
              _invoiceRow('Grand Total:', '₹${cart.getGrandTotal().toStringAsFixed(2)}', theme.colorScheme.primary, true),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            onPressed: () => _handleCheckout(cart, 'razorpay'),
            child: const Text('Pay Securely Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _row(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _invoiceRow(String label, String val, [Color? color, bool isTotal = false]) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      Text(val, style: TextStyle(fontSize: isTotal ? 14 : 11, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}
