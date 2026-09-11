import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/api_config.dart';
import 'services/offline_queue_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _queueService = OfflineQueueService();
    _isOnline = true;
  }

  late OfflineQueueService _queueService;
  bool _isOnline = true;

  static void setOnline(bool online) => _instance.setOnlineStatus(online);
  static bool get online => _instance._isOnline;

  void setOnlineStatus(bool online) => _isOnline = online;

  static Uri _uri(String path) => Uri.parse('$API_BASE_URL$path');

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _defaultHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await _getToken();
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Generic methods with offline support
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    if (!_isOnline) {
      await _queueService.addToQueue('create', _extractEntityType(path), '', body);
      return {'offline': true, 'queued': true};
    }

    try {
      final res = await http.post(_uri(path),
          headers: await _defaultHeaders(),
          body: jsonEncode(body));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception('POST $path failed: ${res.body}');
    } catch (e) {
      await _queueService.addToQueue('create', _extractEntityType(path), '', body);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final entityId = _extractIdFromPath(path);
    if (!_isOnline) {
      await _queueService.addToQueue('update', _extractEntityType(path), entityId, body);
      return {'offline': true, 'queued': true};
    }

    try {
      final res = await http.put(_uri(path),
          headers: await _defaultHeaders(),
          body: jsonEncode(body));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception('PUT $path failed: ${res.body}');
    } catch (e) {
      await _queueService.addToQueue('update', _extractEntityType(path), entityId, body);
      rethrow;
    }
  }

  Future<void> deleteEntity(String path) async {
    final entityId = _extractIdFromPath(path);
    if (!_isOnline) {
      await _queueService.addToQueue('delete', _extractEntityType(path), entityId, {});
      return;
    }

    try {
      final res = await http.delete(_uri(path), headers: await _defaultHeaders());
      if (res.statusCode != 200) throw Exception('DELETE $path failed: ${res.body}');
    } catch (e) {
      await _queueService.addToQueue('delete', _extractEntityType(path), entityId, {});
      rethrow;
    }
  }

  Future<List<dynamic>> getEntities(String path) async {
    final res = await http.get(_uri(path), headers: await _defaultHeaders());
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  // Static Wrappers
  static Future<Map<String, dynamic>> login(String email, String password) => _instance._login(email, password);
  static Future<Map<String, dynamic>> register(String email, String password, String shopName) => _instance._register(email, password, shopName);
  static Future<List<dynamic>> getAllUsers() => _instance.getEntities('/users');
  static Future<List<dynamic>> getAllShops() => _instance.getEntities('/shops');
  static Future<List<dynamic>> getProducts() => _instance.getEntities('/products');
  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> payload) => _instance.post('/products', payload);
  static Future<void> updateProduct(String id, Map<String, dynamic> payload) => _instance.put('/products/$id', payload);
  static Future<void> deleteProduct(String id) => _instance.deleteEntity('/products/$id');
  static Future<List<dynamic>> getSales() => _instance.getEntities('/sales');
  static Future<Map<String, dynamic>> recordSale(Map<String, dynamic> payload) => _instance.post('/sales', payload);
  static Future<void> updateSale(String id, Map<String, dynamic> payload) => _instance.put('/sales/$id', payload);
  static Future<void> deleteSale(String id) => _instance.deleteEntity('/sales/$id');
  static Future<List<dynamic>> getExpenses() => _instance.getEntities('/expenses');
  static Future<Map<String, dynamic>> addExpense(Map<String, dynamic> payload) => _instance.post('/expenses', payload);
  static Future<void> updateExpense(String id, Map<String, dynamic> payload) => _instance.put('/expenses/$id', payload);
  static Future<void> deleteExpense(String id) => _instance.deleteEntity('/expenses/$id');

  // Internal Auth implementation
  Future<Map<String, dynamic>> _login(String email, String password) async {
    final res = await http.post(_uri('/auth/login'),
        headers: await _defaultHeaders(),
        body: jsonEncode({'email': email, 'password': password}));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Login failed: ${res.body}');
  }

  Future<Map<String, dynamic>> _register(String email, String password, String shopName) async {
    final res = await http.post(_uri('/auth/register'),
        headers: await _defaultHeaders(),
        body: jsonEncode({'email': email, 'password': password, 'shopName': shopName}));
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Register failed: ${res.body}');
  }

  // Helper methods
  String _extractEntityType(String path) {
    if (path.contains('/products')) return 'product';
    if (path.contains('/sales')) return 'sale';
    if (path.contains('/expenses')) return 'expense';
    if (path.contains('/shops')) return 'shop';
    return 'unknown';
  }

  String _extractIdFromPath(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }
}
