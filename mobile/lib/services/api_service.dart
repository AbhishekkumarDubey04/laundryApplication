import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  
  // Custom callback to trigger logout when a 401 Unauthorized is intercepted
  void Function()? onUnauthorized;

  ApiService._internal() {
    // Dynamic loopback routing: Android emulators map localhost to 10.0.2.2
    final baseUrl = Platform.isAndroid 
        ? 'http://10.0.2.2:5000/api' 
        : 'http://localhost:5000/api';

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Request/Response Interceptor for authorization and error handling
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('laundry_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('laundry_token');
          await prefs.remove('laundry_user');
          if (onUnauthorized != null) {
            onUnauthorized!();
          }
        }
        return handler.next(error);
      },
    ));
  }

  // Auth operations
  Future<Response> sendOtp(String phone) async {
    return dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<Response> verifyOtp(String phone, String otp) async {
    return dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
  }

  Future<Response> updateProfile(String name, String? email) async {
    return dio.put('/auth/profile', data: {'name': name, 'email': email});
  }

  // Service catalog operations
  Future<Response> getServices() async {
    return dio.get('/services');
  }

  Future<Response> getPricingCatalog() async {
    return dio.get('/services/raw-pricing');
  }

  Future<Response> getCatalogItems() async {
    return dio.get('/services/items');
  }

  Future<Response> addPricingRate(Map<String, dynamic> data) async {
    return dio.post('/services/pricing', data: data);
  }

  Future<Response> deletePricingRate(int id) async {
    return dio.delete('/services/pricing/$id');
  }

  // Address operations
  Future<Response> getAddresses() async {
    return dio.get('/addresses');
  }

  Future<Response> addAddress(Map<String, dynamic> data) async {
    return dio.post('/addresses', data: data);
  }

  Future<Response> updateAddress(int id, Map<String, dynamic> data) async {
    return dio.put('/addresses/$id', data: data);
  }

  Future<Response> deleteAddress(int id) async {
    return dio.delete('/addresses/$id');
  }

  // Order operations
  Future<Response> getOrders() async {
    return dio.get('/orders');
  }

  Future<Response> getOrderById(int id) async {
    return dio.get('/orders/$id');
  }

  Future<Response> createOrder(Map<String, dynamic> data) async {
    return dio.post('/orders', data: data);
  }

  Future<Response> updateOrderStatus(int id, String status) async {
    return dio.put('/orders/$id/status', data: {'status': status});
  }

  Future<Response> updateOrderPaymentStatus(int id, String paymentStatus) async {
    return dio.put('/orders/$id/payment-status', data: {'payment_status': paymentStatus});
  }

  // Payment operations
  Future<Response> createPayment(int orderId, String method) async {
    return dio.post('/payments/create', data: {'order_id': orderId, 'method': method});
  }

  Future<Response> verifyPayment(Map<String, dynamic> data) async {
    return dio.post('/payments/verify', data: data);
  }

  // Notifications
  Future<Response> getNotifications() async {
    return dio.get('/notifications');
  }

  Future<Response> markNotificationsRead() async {
    return dio.put('/notifications/read-all');
  }

  // Coupons
  Future<Response> validateCoupon(String code, double amount) async {
    return dio.post('/coupons/validate', data: {'code': code, 'amount': amount});
  }

  Future<Response> getCoupons() async {
    return dio.get('/coupons');
  }

  Future<Response> createCoupon(Map<String, dynamic> data) async {
    return dio.post('/coupons', data: data);
  }

  Future<Response> toggleCouponStatus(int id) async {
    return dio.put('/coupons/$id/toggle');
  }

  Future<Response> getStats() async {
    return dio.get('/admin/dashboard-stats');
  }
}
