import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final stock = context.watch<StockProvider>();
    final expenseProv = context.watch<ExpenseProvider>();
    final syncProv = context.watch<SyncProvider>();
    
    final shop = auth.currentShop;
    
    final products = stock.products;
    final sales = stock.sales;
    final expenses = expenseProv.expenses;

    final totalSales = sales.fold(0.0, (sum, item) => sum + item.totalPrice);
    final grossProfit = sales.fold(0.0, (sum, item) => sum + item.profit);
    final totalExpenses = expenseProv.getTotalExpenses(expenses);
    final netProfit = grossProfit - totalExpenses;

    // Find most sold product
    Map<String, int> productQuantities = {};
    for (var sale in sales) {
      productQuantities[sale.productName] = (productQuantities[sale.productName] ?? 0) + sale.quantity;
    }
    String topProduct = "None";
    if (productQuantities.isNotEmpty) {
      topProduct = (productQuantities.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }

    final lowStockProducts = products.where((p) => p.stock < 5).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          if (auth.isOfflineMode || syncProv.hasPendingOperations)
            Container(
              width: double.infinity,
              color: syncProv.hasPendingOperations ? Colors.blue.shade800 : Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    syncProv.hasPendingOperations ? Icons.sync : Icons.wifi_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      syncProv.hasPendingOperations
                          ? 'Syncing ${syncProv.pendingCount} items to cloud...'
                          : 'Offline Mode: Data sync is paused. Login with internet to sync.',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (syncProv.hasPendingOperations)
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop?.name.toUpperCase() ?? l10n.dashboard.toUpperCase(), 
                    style: const TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(l10n.income, 'TZS ${CurrencyFormatter.format(totalSales)}', Icons.monetization_on, AppColors.martiamGreen)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatCard(l10n.expenses, 'TZS ${CurrencyFormatter.format(totalExpenses)}', Icons.payments, Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(l10n.grossProfit, 'TZS ${CurrencyFormatter.format(grossProfit)}', Icons.trending_up, AppColors.accentGreen)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatCard(l10n.netProfit, 'TZS ${CurrencyFormatter.format(netProfit)}', Icons.account_balance, netProfit >= 0 ? AppColors.martiamGreen : Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(l10n.inventorySize, '${products.length} Products', Icons.inventory_2, AppColors.darkGreen)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatCard('Top Product', topProduct, Icons.star, Colors.amber.shade700)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(l10n.lowStockAlert, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                  const SizedBox(height: 15),
                  if (lowStockProducts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.lowStockAlert, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    Text('${lowStockProducts.length} items need restocking.', style: TextStyle(color: Colors.red.shade900)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 5),
                          Text('Stock levels are healthy', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
          ),
        ],
      ),
    );
  }
}
