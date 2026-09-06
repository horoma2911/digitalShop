import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models/user.dart';
import '../models/shop.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  Shop? _currentShop;
  bool _isOfflineMode = false;
  final Logger _logger = Logger();

  User? get currentUser => _currentUser;
  Shop? get currentShop => _currentShop;
  bool get isOfflineMode => _isOfflineMode;

  @visibleForTesting
  set currentUser(User? user) => _currentUser = user;

  @visibleForTesting
  set currentShop(Shop? shop) => _currentShop = shop;

  AuthProvider() {
    // No-op for REST-based auth; keep constructor for compatibility
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password + "digital_shop_salt"); // Simple salt
    return sha256.convert(bytes).toString();
  }

  Future<void> _cacheCredentials(User user, String password, [String? token]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_id', user.id);
    await prefs.setString('cached_username', user.username);
    await prefs.setString('cached_role', user.role.toString());
    await prefs.setString('cached_shop_id', user.shopId ?? 'global_shop');
    await prefs.setString('cached_password_hash', _hashPassword(password));
    if (token != null) await prefs.setString('auth_token', token);
  }

  Future<String?> _tryOfflineLogin(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEmail = prefs.getString('cached_username');
    final cachedHash = prefs.getString('cached_password_hash');

    if (cachedEmail == email && cachedHash == _hashPassword(password)) {
      _currentUser = User(
        id: prefs.getString('cached_user_id') ?? '',
        username: cachedEmail!,
        password: '',
        role: UserRole.values.firstWhere((e) => e.toString() == prefs.getString('cached_role')),
        shopId: prefs.getString('cached_shop_id'),
      );

      _isOfflineMode = true;

      // Load shop name if possible
      final shopName = prefs.getString('cached_shop_name') ?? 'Offline Shop';
      _currentShop = Shop(id: _currentUser!.shopId ?? 'global_shop', ownerId: _currentUser!.id, name: shopName);

      _logger.i('Successfully logged in offline as $email');
      notifyListeners();
      return null; // Success in offline mode
    }
    _logger.w('Offline login failed for $email: No matching cached credentials.');
    return "Connection lost. No offline account found for this email.";
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await ApiClient.login(email, password);
      if (res.containsKey('user')) {
        final u = res['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson({
          'id': u['id'],
          'username': u['email'],
          'password': '',
          'role': u['role'],
          'shopId': u['shopId'],
        });
        if (res.containsKey('shop')) _currentShop = Shop.fromJson(res['shop']);
        _isOfflineMode = false;
        final token = res['token'] as String?;
        await _cacheCredentials(_currentUser!, password, token);
        _logger.i('Successfully logged in online as $email');
        notifyListeners();
        return null;
      }
      return 'Login failed. Unexpected response.';
    } catch (e) {
      _logger.e('Login error: $e');
      // Try offline
      return await _tryOfflineLogin(email, password);
    }
  }

  Future<String?> register(String email, String password, String shopName) async {
    try {
      final res = await ApiClient.register(email, password, shopName);
      if (res.containsKey('user')) {
        final u = res['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson({
          'id': u['id'],
          'username': u['email'],
          'password': '',
          'role': u['role'],
          'shopId': u['shopId'],
        });
        if (res.containsKey('shop')) _currentShop = Shop.fromJson(res['shop']);
        _isOfflineMode = false;
        final token = res['token'] as String?;
        await _cacheCredentials(_currentUser!, password, token);
        _logger.i('Successfully registered $email and associated with shop: ${_currentShop?.name}');
        notifyListeners();
        return null;
      }
      return 'Registration failed. Unexpected response.';
    } catch (e) {
      _logger.e('Register error: $e');
      return 'An unexpected error occurred during registration.';
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _currentUser = null;
    _currentShop = null;
    _isOfflineMode = false;
    _logger.i('User logged out.');
    notifyListeners();
  }

  Future<List<User>> getAllUsers() async {
    try {
      final list = await ApiClient.getAllUsers();
      return list.map((e) {
        final m = Map<String, dynamic>.from(e);
        return User.fromJson({
          'id': m['id'],
          'username': m['email'],
          'password': '',
          'role': m['role'],
          'shopId': m['shopId'],
        });
      }).toList();
    } catch (e) {
      _logger.e('Failed to get all users: $e');
      return [];
    }
  }

  Future<List<Shop>> getAllShops() async {
    try {
      final list = await ApiClient.getAllShops();
      return list.map((e) => Shop.fromJson(e)).toList();
    } catch (e) {
      _logger.e('Failed to get all shops: $e');
      return [];
    }
  }
}
