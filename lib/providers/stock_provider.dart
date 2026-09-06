import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../utils/notification_service.dart';
import '../api_client.dart';

class StockProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Sale> _sales = [];
  bool _isSyncing = false;
  bool _isOnline = true;

  List<Product> get products => _products;
  List<Sale> get sales => _sales;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;

  // Fetch current state once (no realtime)
  Future<void> listenToData() async {
    try {
      _isOnline = true;
      final p = await ApiClient.getProducts();
      final s = await ApiClient.getSales();
      _products = p.map((e) => Product.fromJson(e)).toList();
      _sales = s.map((e) => Sale.fromJson(e)).toList();
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isOnline = false;
      debugPrint('API listenToData error: $e');
      notifyListeners();
    }
  }

  Future<void> syncWithServer() async {
    // No-op for REST; server operations are immediate
    return;
  }

  Future<void> clearLocalCache() async {
    // No Firestore persistence to clear in REST mode
    return;
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required String barcode,
    required double costPrice,
    required double salePrice,
    required int stock,
  }) async {
    try {
      const sharedShopId = 'global_shop';
      final payload = {
        'shopId': sharedShopId,
        'name': name,
        'category': category,
        'barcode': barcode,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'stock': stock,
      };
      final created = await ApiClient.addProduct(payload);
      _products.add(Product.fromJson(created));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    try {
      await ApiClient.updateProduct(updatedProduct.id, updatedProduct.toJson());
      final idx = _products.indexWhere((p) => p.id == updatedProduct.id);
      if (idx != -1) _products[idx] = updatedProduct;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await ApiClient.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> recordSale(Product product, int quantity) async {
    if (product.stock < quantity) throw Exception('Insufficient stock');

    try {
      final payload = {'productId': product.id, 'quantity': quantity};
      final saleJson = await ApiClient.recordSale(payload);
      final sale = Sale.fromJson(saleJson);

      // Update local product and sales
      final idx = _products.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        final newStock = _products[idx].stock - quantity;
        _products[idx] = _products[idx].copyWith(stock: newStock);
        if (newStock < 5) {
          NotificationService.showLowStockNotification(
              productName: _products[idx].name, remainingStock: newStock);
        }
      }

      _sales.add(sale);
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording sale: $e');
      rethrow;
    }
  }

  Future<void> deleteSale(Sale sale) async {
    try {
      await ApiClient.deleteSale(sale.id);
      // Revert stock locally
      final idx = _products.indexWhere((p) => p.id == sale.productId);
      if (idx != -1) {
        _products[idx] = _products[idx].copyWith(stock: _products[idx].stock + sale.quantity);
      }
      _sales.removeWhere((s) => s.id == sale.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting sale: $e');
      rethrow;
    }
  }

  Future<void> updateSale(Sale oldSale, int newQuantity) async {
    try {
      await ApiClient.updateSale(oldSale.id, {'quantity': newQuantity});
      // Adjust local product stock
      final productIdx = _products.indexWhere((p) => p.id == oldSale.productId);
      if (productIdx == -1) throw Exception('Product not found');
      
      final product = _products[productIdx];
      final stockDiff = oldSale.quantity - newQuantity;
      _products[productIdx] = product.copyWith(stock: product.stock + stockDiff);

      // Update sale locally
      final idx = _sales.indexWhere((s) => s.id == oldSale.id);
      if (idx != -1) {
        _sales[idx] = _sales[idx].copyWith(
          quantity: newQuantity,
          totalPrice: product.salePrice * newQuantity,
          profit: (product.salePrice - product.costPrice) * newQuantity,
        );
      }

      if (_products[productIdx].stock < 5) {
        NotificationService.showLowStockNotification(
            productName: _products[productIdx].name, remainingStock: _products[productIdx].stock);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating sale: $e');
      rethrow;
    }
  }
}
