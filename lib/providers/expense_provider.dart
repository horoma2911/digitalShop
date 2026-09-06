import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../api_client.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isSyncing = false;

  List<Expense> get expenses => _expenses;
  bool get isSyncing => _isSyncing;

  Future<void> listenToData() async {
    try {
      final list = await ApiClient.getExpenses();
      _expenses = list.map((e) => Expense.fromJson(e)).toList();
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('API Expenses listen error: $e');
    }
  }

  Future<void> syncWithServer() async {
    // No-op for REST
  }

  Future<void> addExpense({
    required String category,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    const sharedShopId = 'global_shop';
    final payload = {
      'shopId': sharedShopId,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
    };
    final created = await ApiClient.addExpense(payload);
    _expenses.add(Expense.fromJson(created));
    notifyListeners();
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    await ApiClient.updateExpense(updatedExpense.id, updatedExpense.toJson());
    final idx = _expenses.indexWhere((e) => e.id == updatedExpense.id);
    if (idx != -1) _expenses[idx] = updatedExpense;
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    await ApiClient.deleteExpense(expenseId);
    _expenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
  }

  double getTotalExpenses(List<Expense> shopExpenses, {DateTimeRange? range}) {
    if (range == null) {
      return shopExpenses.fold(0.0, (total, item) => total + item.amount);
    }
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);

    return shopExpenses
        .where((e) => (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) && 
                      (e.date.isBefore(end) || e.date.isAtSameMomentAs(end)))
        .fold(0.0, (total, item) => total + item.amount);
  }
}
