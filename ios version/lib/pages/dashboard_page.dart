import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';
import 'booking_flow_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  List<Order> _orders = [];
  List<Address> _addresses = [];
  List<NotificationModel> _notifications = [];
  bool _isLoadingOrders = true;
  bool _isLoadingAddresses = true;
  int _unreadNotifications = 0;

  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSavingProfile = false;

  final _addressFormKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _addressTag = 'Home';
  bool _addressIsDefault = false;
  Address? _editingAddress;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.user?.name ?? '';
    _emailController.text = auth.user?.email ?? '';
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _fetchOrders();
    _fetchAddresses();
    _fetchNotifications();
  }

  Future<void> _fetchOrders() async {
    if (mounted) setState(() => _isLoadingOrders = true);
    try {
      final res = await ApiService().getOrders();
      final list = res.data as List;
      if (mounted) {
        setState(() {
          _orders = list
              .map((o) => Order.fromJson(o as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _fetchAddresses() async {
    if (mounted) setState(() => _isLoadingAddresses = true);
    try {
      final res = await ApiService().getAddresses();
      final list = res.data as List;
      if (mounted) {
        setState(() {
          _addresses = list
              .map((a) => Address.fromJson(a as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await ApiService().getNotifications();
      final list = res.data as List;
      final nl = list
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _notifications = nl;
          _unreadNotifications =
              nl.where((n) => n.status == 'unread').length;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    PlatformUtils.hapticMedium();
    setState(() => _isSavingProfile = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      await ApiService()
          .updateProfile(name, email.isEmpty ? null : email);
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false)
          .updateProfileLocal(name, email.isEmpty ? null : email);
      if (!mounted) return;
      PlatformUtils.hapticSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')));
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _handleSaveAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;
    PlatformUtils.hapticMedium();
    final payload = {
      'tag': _addressTag,
      'address_line_1': _addressLine1Controller.text.trim(),
      'address_line_2': _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'is_default': _addressIsDefault,
    };
    try {
      if (_editingAddress == null) {
        await ApiService().addAddress(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address added successfully')));
      } else {
        await ApiService().updateAddress(_editingAddress!.id, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address updated successfully')));
      }
      if (!mounted) return;
      Navigator.pop(context);
      _fetchAddresses();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address')));
    }
  }

  Future<void> _handleDeleteAddress(int id) async {
    PlatformUtils.hapticMedium();
    try {
      await ApiService().deleteAddress(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')));
      _fetchAddresses();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete address')));
    }
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      await ApiService().markNotificationsRead();
      _fetchNotifications();
    } catch (_) {}
  }

  void _showAddressDialog([Address? addr]) {
    _editingAddress = addr;
    if (addr == null) {
      _addressLine1Controller.clear();
      _addressLine2Controller.clear();
      _cityController.clear();
      _stateController.clear();
      _pincodeController.clear();
      _addressTag = 'Home';
      _addressIsDefault = false;
    } else {
      _addressLine1Controller.text = addr.addressLine1;
      _addressLine2Controller.text = addr.addressLine2 ?? '';
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _pincodeController.text = addr.pincode;
      _addressTag = addr.tag;
      _addressIsDefault = addr.isDefault;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: _addressFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          addr == null
                              ? 'Create New Address'
                              : 'Update Address',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(ctx),
                          child: const Icon(CupertinoIcons.xmark_circle_fill,
                              color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _addressTag,
                    decoration:
                        const InputDecoration(labelText: 'Tag'),
                    items: ['Home', 'Work', 'Other']
                        .map((tag) =>
                            DropdownMenuItem(value: tag, child: Text(tag)))
                        .toList(),
                    onChanged: (val) => setS(() => _addressTag = val!),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressLine1Controller,
                    decoration: const InputDecoration(
                        labelText: 'Address Line 1'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressLine2Controller,
                    decoration: const InputDecoration(
                        labelText: 'Address Line 2 (Optional)'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration:
                              const InputDecoration(labelText: 'City'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration:
                              const InputDecoration(labelText: 'State'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pincodeController,
                    decoration:
                        const InputDecoration(labelText: 'Pincode'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) =>
                        v!.length != 6 ? 'Must be 6 digits' : null,
                  ),
                  CheckboxListTile(
                    title: const Text('Set as default address',
                        style: TextStyle(fontSize: 12)),
                    value: _addressIsDefault,
                    onChanged: (val) =>
                        setS(() => _addressIsDefault = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: _handleSaveAddress,
                      child: const Text('Save Address',
                          style: TextStyle(color: Colors.white)),
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

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Notifications',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_unreadNotifications > 0)
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _markAllNotificationsRead();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Mark all read',
                        style: TextStyle(fontSize: 12))),
            ]),
            const Divider(),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text('No alerts found',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final n = _notifications[idx];
                        return ListTile(
                          title: Text(n.title,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: n.status == 'unread'
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              Text(
                                  n.createdAt
                                      .replaceFirst('T', ' ')
                                      .substring(0, 16),
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _currentIndex == 1
          ? null
          : AppBar(
              title: const Text('LaundryIndia'),
              actions: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () {
                    PlatformUtils.hapticLight();
                    auth.toggleTheme();
                  },
                  child: Icon(
                    auth.isDarkMode
                        ? CupertinoIcons.sun_max
                        : CupertinoIcons.moon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () {
                        PlatformUtils.hapticLight();
                        _showNotificationsSheet();
                      },
                      child: Icon(CupertinoIcons.bell,
                          color: theme.foregroundColor, size: 22),
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        top: 8,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text('$_unreadNotifications',
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(right: 12),
                  onPressed: () async {
                    PlatformUtils.hapticMedium();
                    await auth.logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Icon(CupertinoIcons.square_arrow_right,
                      color: Colors.red, size: 22),
                ),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeView(theme, auth),
          BookingFlowPage(
              onClose: () => setState(() => _currentIndex = 0)),
          _buildOrdersView(theme),
          _buildProfileView(theme, auth),
        ],
      ),
      // iOS-style bottom tab bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        elevation: 0,
        onTap: (index) {
          PlatformUtils.hapticLight();
          setState(() => _currentIndex = index);
          _loadData();
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.plus_circle), label: 'Book'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeView(ThemeData theme, AuthProvider auth) {
    final activeOrdersCount =
        _orders.where((o) => o.status != 'delivered').length;
    final completedOrdersCount =
        _orders.where((o) => o.status == 'delivered').length;
    final totalPaidSpend = _orders
        .where((o) => o.paymentStatus == 'paid')
        .fold(0.0, (sum, o) => sum + o.grandTotal);
    final user = auth.user;

    return CustomScrollView(
      physics: PlatformUtils.scrollPhysics,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // User card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.15),
                        child: Text(user?.name[0] ?? 'U',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? '',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(user?.phone ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                  user?.role.toUpperCase() ?? '',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KPI Metrics
              Row(
                children: [
                  _buildKpiCard('Active', '$activeOrdersCount',
                      CupertinoIcons.waveform, Colors.blue),
                  const SizedBox(width: 12),
                  _buildKpiCard('Delivered', '$completedOrdersCount',
                      CupertinoIcons.checkmark_circle, Colors.green),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                      'Spend',
                      '₹${totalPaidSpend.toStringAsFixed(0)}',
                      LucideIcons.indianRupee,
                      theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 24),

              // Book Now Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: auth.isDarkMode
                        ? [const Color(0xFF1C1C1E), const Color(0xFF111215)]
                        : [const Color(0xFFE5E7EB), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          theme.colorScheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need Laundry Done?',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: auth.isDarkMode
                                ? Colors.white
                                : const Color(0xFF1C1C1E))),
                    const SizedBox(height: 6),
                    const Text(
                        'Book premium washing, dry cleaning, or steam pressing in seconds.',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        PlatformUtils.hapticMedium();
                        setState(() => _currentIndex = 1);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.plus_circle,
                              size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Book Order Now',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  Icon(icon, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersView(ThemeData theme) {
    if (_isLoadingOrders) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.cube_box,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No orders found',
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: () {
                PlatformUtils.hapticLight();
                setState(() => _currentIndex = 1);
              },
              child: const Text('Make your first booking'),
            )
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _orders.length,
      physics: PlatformUtils.scrollPhysics,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, idx) {
        final o = _orders[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Order #${o.id}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
                'Pickup: ${o.pickupDate}\nMode: ${o.deliveryPreference.toUpperCase()}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${o.grandTotal}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                    o.status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                        fontSize: 9,
                        color: o.status == 'delivered'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            onTap: () {
              PlatformUtils.hapticLight();
              Navigator.pushNamed(context, '/track/${o.id}')
                  .then((_) => _loadData());
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileView(ThemeData theme, AuthProvider auth) {
    return ListView(
      physics: PlatformUtils.scrollPhysics,
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Name'),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email Address'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed:
                          _isSavingProfile ? null : _handleSaveProfile,
                      child: _isSavingProfile
                          ? const CupertinoActivityIndicator(
                              color: Colors.white)
                          : const Text('Save Profile',
                              style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Saved Addresses',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                PlatformUtils.hapticLight();
                _showAddressDialog();
              },
              child: Text('+ Add',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingAddresses
            ? const Center(child: CupertinoActivityIndicator())
            : _addresses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text(
                            'No addresses saved. Add one to start.',
                            style: TextStyle(color: Colors.grey))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addresses.length,
                    itemBuilder: (context, idx) {
                      final a = _addresses[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.mapPin,
                                  color: theme.colorScheme.primary,
                                  size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(a.tag,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      if (a.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1),
                                          decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      4)),
                                          child: const Text('DEFAULT',
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.green,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        )
                                      ]
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(a.addressLine1,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                    Text(
                                        '${a.city}, ${a.state} - ${a.pincode}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _showAddressDialog(a),
                                  child: const Icon(CupertinoIcons.pencil,
                                      size: 18, color: Colors.blue)),
                              CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _handleDeleteAddress(a.id),
                                  child: const Icon(CupertinoIcons.trash,
                                      size: 18, color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}

extension on ThemeData {
  Color get foregroundColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black87;
}
