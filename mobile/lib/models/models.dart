class User {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
      };
}

class Service {
  final int id;
  final String name;
  final String? description;
  final List<ServiceItem> items;

  Service({
    required this.id,
    required this.name,
    this.description,
    this.items = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    return Service(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      items: rawItems.map((item) => ServiceItem.fromJson(item)).toList(),
    );
  }
}

class ServiceItem {
  final int id;
  final String name;
  final double price;
  final String category;

  ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as int,
      name: json['name'] as String,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'] as String? ?? 'General',
    );
  }
}

class Address {
  final int id;
  final String tag;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Address({
    required this.id,
    required this.tag,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int,
      tag: json['tag'] as String,
      addressLine1: json['address_line_1'] as String,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'is_default': isDefault,
      };
}

class Order {
  final int id;
  final int userId;
  final int pickupAddressId;
  final String pickupDate;
  final String pickupTimeSlot;
  final String deliveryPreference;
  final String status;
  final double grandTotal;
  final double totalAmount;
  final double discountAmount;
  final double taxAmount;
  final double deliveryCharges;
  final String? couponCode;
  final String? paymentGateway;
  final String paymentStatus;
  final String userName;
  final String userPhone;
  final String deliveryDate;

  Order({
    required this.id,
    required this.userId,
    required this.pickupAddressId,
    required this.pickupDate,
    required this.pickupTimeSlot,
    required this.deliveryPreference,
    required this.status,
    required this.grandTotal,
    required this.totalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.deliveryCharges,
    this.couponCode,
    this.paymentGateway,
    required this.paymentStatus,
    required this.userName,
    required this.userPhone,
    required this.deliveryDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      pickupAddressId: json['pickup_address_id'] as int? ?? 0,
      pickupDate: json['pickup_date'] as String? ?? '',
      pickupTimeSlot: json['pickup_time_slot'] as String? ?? '',
      deliveryPreference: json['delivery_preference'] as String? ?? 'standard',
      status: json['status'] as String? ?? 'created',
      grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount'].toString()) ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount'].toString()) ?? 0.0,
      deliveryCharges: double.tryParse(json['delivery_charges'].toString()) ?? 0.0,
      couponCode: json['coupon_code'] as String?,
      paymentGateway: json['payment_gateway'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      userName: json['user_name'] as String? ?? '',
      userPhone: json['user_phone'] as String? ?? '',
      deliveryDate: json['delivery_date'] as String? ?? '',
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int itemId;
  final int serviceId;
  final int quantity;
  final double totalPrice;
  final String itemName;
  final String serviceName;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.serviceId,
    required this.quantity,
    required this.totalPrice,
    required this.itemName,
    required this.serviceName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int? ?? 0,
      itemId: json['item_id'] as int? ?? 0,
      serviceId: json['service_id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      itemName: json['item_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
    );
  }
}

class Coupon {
  final String code;
  final String discountType;
  final double discountValue;
  final double discountAmount;

  Coupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount'].toString()) ?? 0.0,
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String status;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class PricingRow {
  final int id;
  final int serviceId;
  final int itemId;
  final String serviceName;
  final String itemName;
  final String itemCategory;
  final double price;

  PricingRow({
    required this.id,
    required this.serviceId,
    required this.itemId,
    required this.serviceName,
    required this.itemName,
    required this.itemCategory,
    required this.price,
  });

  factory PricingRow.fromJson(Map<String, dynamic> json) {
    return PricingRow(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      itemId: json['item_id'] as int,
      serviceName: json['service_name'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      itemCategory: json['item_category'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}
