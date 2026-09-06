import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../models/sale.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_colors.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stock = context.watch<StockProvider>();
    final sales = stock.sales;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: sales.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(l10n.noTransactionsYet, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final sale = sales[sales.length - 1 - index]; // Newest first
                return Card(
                  child: InkWell(
                    onLongPress: () => _showSaleOptions(context, sale),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_bag, color: AppColors.martiamGreen),
                      ),
                      title: Text(sale.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                      subtitle: Text(DateFormat('MMM dd, yyyy • HH:mm').format(sale.date), style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('TZS ${CurrencyFormatter.format(sale.totalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.martiamGreen)),
                              Text('${l10n.quantity}: ${sale.quantity} | ${l10n.grossProfit}: TZS ${CurrencyFormatter.format(sale.profit)}', style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditSaleDialog(context, sale);
                              } else if (value == 'delete') {
                                _showDeleteSaleConfirmation(context, sale);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                              PopupMenuItem(value: 'delete', child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showSaleOptions(BuildContext context, Sale sale) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.martiamGreen),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditSaleDialog(context, sale);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete),
              onTap: () {
                Navigator.pop(context);
                _showDeleteSaleConfirmation(context, sale);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSaleConfirmation(BuildContext context, Sale sale) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete}?'),
        content: const Text('Deleting this sale will restore the items back to your inventory stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<StockProvider>().deleteSale(sale);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSaleDialog(BuildContext context, Sale sale) {
    final l10n = AppLocalizations.of(context)!;
    final qtyCtrl = TextEditingController(text: sale.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.edit}: ${sale.productName}'),
        content: TextField(
          controller: qtyCtrl,
          decoration: InputDecoration(labelText: l10n.quantity, prefixIcon: const Icon(Icons.numbers)),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.red))),
          ElevatedButton(
            onPressed: () {
              try {
                context.read<StockProvider>().updateSale(sale, int.parse(qtyCtrl.text));
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }
}
