import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_colors.dart';
import '../utils/receipt_service.dart';
import 'widgets/barcode_scanner_view.dart';

class RecordSaleScreen extends StatefulWidget {
  const RecordSaleScreen({super.key});

  @override
  State<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends State<RecordSaleScreen> {
  String _searchQuery = '';
  Product? _selectedProduct;
  final _qtyController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stock = context.watch<StockProvider>();
    final products = stock.products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordSaleTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectProduct, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.martiamGreen),
                      onPressed: () async {
                        final code = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
                        );
                        if (code != null) {
                          // Try to find product by barcode
                          final allShopProducts = stock.products;
                          try {
                            final realMatch = allShopProducts.firstWhere((p) => p.barcode == code);
                            setState(() {
                              _selectedProduct = realMatch;
                              _searchQuery = '';
                            });
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product not found for this barcode')));
                            }
                          }
                        }
                      },
                    ),
                    if (_searchQuery.isNotEmpty) 
                      IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = '')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final isSelected = _selectedProduct?.id == p.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.lightGreen,
                      title: Text(p.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text('${p.category} • ${l10n.stock}: ${p.stock}'),
                      trailing: Text('TZS ${CurrencyFormatter.format(p.salePrice)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.martiamGreen)),
                      onTap: () => setState(() => _selectedProduct = p),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedProduct != null) ...[
              Text(l10n.quantity, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      decoration: InputDecoration(labelText: l10n.amountToSell),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.totalPrice, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                      Text(
                        'TZS ${CurrencyFormatter.format((_selectedProduct?.salePrice ?? 0) * (int.tryParse(_qtyController.text) ?? 0))}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.martiamGreen),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(l10n.confirmTransaction, style: const TextStyle(letterSpacing: 1.2)),
              ),
            ] else 
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(l10n.noProductsFound, style: const TextStyle(color: AppColors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submitSale() async {
    if (_selectedProduct == null) return;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
      return;
    }

    try {
      final stockProvider = context.read<StockProvider>();
      final auth = context.read<AuthProvider>();
      await stockProvider.recordSale(_selectedProduct!, qty);
      
      if (!mounted) return;
      
      final updatedProduct = stockProvider.products.firstWhere((p) => p.id == _selectedProduct!.id);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sold successfully!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              if (updatedProduct.stock < 5)
                Text(
                  'WARNING: Low Stock! (${updatedProduct.stock} left)',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('DONE'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ReceiptService.generateAndOpenReceipt(
                  shopName: auth.currentShop?.name ?? 'DigitalShop',
                  product: _selectedProduct!,
                  quantity: qty,
                );
              },
              icon: const Icon(Icons.receipt),
              label: const Text('GENERATE RECEIPT'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.martiamGreen),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
}
