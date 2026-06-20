import 'package:flutter/material.dart';
import '../models/models.dart';

class LocalCartItem {
  final int serviceId;
  final String serviceName;
  final int itemId;
  final String itemName;
  final double price;
  final String category;
  int quantity;

  LocalCartItem({
    required this.serviceId,
    required this.serviceName,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.category,
    required this.quantity,
  });
}

class CartProvider with ChangeNotifier {
  final List<LocalCartItem> _items = [];
  int? _pickupAddressId;
  String? _pickupDate;
  String? _pickupTimeSlot;
  String _deliveryPreference = 'standard';
  Coupon? _coupon;

  List<LocalCartItem> get items => _items;
  int? get pickupAddressId => _pickupAddressId;
  String? get pickupDate => _pickupDate;
  String? get pickupTimeSlot => _pickupTimeSlot;
  String get deliveryPreference => _deliveryPreference;
  Coupon? get coupon => _coupon;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(LocalCartItem newItem) {
    final idx = _items.indexWhere(
      (i) => i.serviceId == newItem.serviceId && i.itemId == newItem.itemId,
    );
    if (idx >= 0) {
      _items[idx].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
  }

  void removeItem(int serviceId, int itemId) {
    _items.removeWhere((i) => i.serviceId == serviceId && i.itemId == itemId);
    notifyListeners();
  }

  void updateQuantity(int serviceId, int itemId, int quantity) {
    final idx = _items.indexWhere((i) => i.serviceId == serviceId && i.itemId == itemId);
    if (idx >= 0) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void setAddress(int addressId) {
    _pickupAddressId = addressId;
    notifyListeners();
  }

  void setSchedule(String date, String timeSlot) {
    _pickupDate = date;
    _pickupTimeSlot = timeSlot;
    notifyListeners();
  }

  void setDeliveryPreference(String pref) {
    _deliveryPreference = pref;
    notifyListeners();
  }

  void setCoupon(Coupon? cp) {
    _coupon = cp;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _pickupAddressId = null;
    _pickupDate = null;
    _pickupTimeSlot = null;
    _deliveryPreference = 'standard';
    _coupon = null;
    notifyListeners();
  }

  double getSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double getDiscountAmount() {
    if (_coupon == null) return 0.0;
    return _coupon!.discountAmount;
  }

  double getDeliveryCharges() {
    double baseCharges = getSubtotal() >= 500.0 ? 0.0 : 30.0;
    if (_deliveryPreference == 'express') {
      baseCharges += 50.0;
    } else if (_deliveryPreference == 'same_day') {
      baseCharges += 100.0;
    }
    return baseCharges;
  }

  double getTax() {
    final double taxableAmount = getSubtotal() - getDiscountAmount();
    return (taxableAmount > 0.0 ? taxableAmount : 0.0) * 0.18; // 18% GST
  }

  double getGrandTotal() {
    final double total = getSubtotal() - getDiscountAmount() + getDeliveryCharges() + getTax();
    return total > 0.0 ? total : 0.0;
  }
}
