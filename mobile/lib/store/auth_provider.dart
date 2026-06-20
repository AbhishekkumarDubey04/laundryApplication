import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  bool _isDarkMode = false;

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isDarkMode => _isDarkMode;
  bool get isAdmin => _user?.role == 'admin';

  AuthProvider() {
    // Connect api service unauthorized callback
    ApiService().onUnauthorized = () {
      _clearLocalAuth();
    };
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('laundry_token');
    
    final userJson = prefs.getString('laundry_user');
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _token = null;
      }
    }
    
    final theme = prefs.getString('laundry_theme') ?? 'light';
    _isDarkMode = theme == 'dark';
    notifyListeners();
  }

  Future<void> setAuth(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('laundry_token', token);
    await prefs.setString('laundry_user', jsonEncode(user.toJson()));
    
    _token = token;
    _user = user;
    notifyListeners();
  }

  Future<void> updateProfileLocal(String name, String? email) async {
    if (_user == null) return;
    
    final updatedUser = User(
      id: _user!.id,
      name: name,
      phone: _user!.phone,
      email: email,
      role: _user!.role,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('laundry_user', jsonEncode(updatedUser.toJson()));
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('laundry_theme', _isDarkMode ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearLocalAuth();
  }

  Future<void> _clearLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('laundry_token');
    await prefs.remove('laundry_user');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
