import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_colors.dart';
import 'widgets/barcode_scanner_view.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'General', 'Electronics', 'Spare Parts', 'Lubricants', 'Food', 'Clothing', 'Beverages', 'Home'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stock = context.watch<StockProvider>();
    final products = stock.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: l10n.searchProducts,
                    prefixIcon: const Icon(Icons.search, color: AppColors.martiamGreen),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.martiamGreen),
                      onPressed: () async {
                        final code = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
                        );
                        if (code != null) {
                          setState(() => _searchQuery = code);
                        }
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (v) => setState(() => _selectedCategory = cat),
                          selectedColor: AppColors.darkGreen,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.martiamGreen),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(child: Text(l10n.noProductsFound, style: TextStyle(color: Colors.grey.shade400)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductFormDialog(context),
        backgroundColor: AppColors.martiamGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isLowStock = product.stock < 5;
    
    return Card(
      child: InkWell(
        onLongPress: () => _showProductOptions(context, product),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isLowStock ? Colors.red.shade50 : AppColors.lightGreen,
            child: Text(
              product.name[0].toUpperCase(), 
              style: TextStyle(
                color: isLowStock ? Colors.red : AppColors.martiamGreen, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen))),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: const Text('LOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.category, style: const TextStyle(color: AppColors.martiamGreen, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.inventory, size: 14, color: isLowStock ? Colors.red : AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.stock}: ${product.stock}', 
                    style: TextStyle(color: isLowStock ? Colors.red : AppColors.grey, fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal)
                  ),
                  const SizedBox(width: 15),
                  const Icon(Icons.sell, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('TZS ${CurrencyFormatter.format(product.salePrice)}', style: const TextStyle(color: AppColors.martiamGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.martiamGreen, size: 20),
                onPressed: () => _showProductFormDialog(context, product: product),
              ),
              Container(
                decoration: BoxDecoration(color: AppColors.martiamGreen, borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                  onPressed: () => _showSaleDialog(context, product),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductOptions(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.martiamGreen),
              title: Text(l10n.editProduct),
              onTap: () {
                Navigator.pop(context);
                _showProductFormDialog(context, product: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete}?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<StockProvider>().deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog(BuildContext context, {Product? product}) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: product?.name);
    final barcodeCtrl = TextEditingController(text: product?.barcode);
    final costCtrl = TextEditingController(text: product?.costPrice.toString());
    final saleCtrl = TextEditingController(text: product?.salePrice.toString());
    final stockCtrl = TextEditingController(text: product?.stock.toString());
    String category = product?.category ?? _categories[1];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? l10n.addProduct : l10n.editProduct, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.productName)),
                const SizedBox(height: 10),
                TextField(
                  controller: barcodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final code = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
                        );
                        if (code != null) setDialogState(() => barcodeCtrl.text = code);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: costCtrl, decoration: InputDecoration(labelText: l10n.costPrice), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: saleCtrl, decoration: InputDecoration(labelText: l10n.salePrice), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: stockCtrl, decoration: InputDecoration(labelText: l10n.initialStock), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
              onPressed: () async {
                final stockProv = context.read<StockProvider>();
                
                try {
                  if (product == null) {
                    await stockProv.addProduct(
                      name: nameCtrl.text,
                      category: category,
                      barcode: barcodeCtrl.text,
                      costPrice: double.parse(costCtrl.text),
                      salePrice: double.parse(saleCtrl.text),
                      stock: int.parse(stockCtrl.text),
                    );
                  } else {
                    await stockProv.updateProduct(product.copyWith(
                      name: nameCtrl.text,
                      category: category,
                      barcode: barcodeCtrl.text,
                      costPrice: double.parse(costCtrl.text),
                      salePrice: double.parse(saleCtrl.text),
                      stock: int.parse(stockCtrl.text),
                    ));
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(product == null ? l10n.save : l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDialog(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.recordSale}: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: qtyCtrl,
          decoration: InputDecoration(labelText: l10n.quantity, prefixIcon: const Icon(Icons.numbers)),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            onPressed: () {
              try {
                context.read<StockProvider>().recordSale(product, int.parse(qtyCtrl.text));
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
