class Product {
  final String id;
  final String shopId;
  final String name;
  final String category;
  final String barcode;
  final double costPrice;
  final double salePrice;
  final int stock;

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    required this.barcode,
    required this.costPrice,
    required this.salePrice,
    required this.stock,
  });

  Product copyWith({
    String? id,
    String? shopId,
    String? name,
    String? category,
    String? barcode,
    double? costPrice,
    double? salePrice,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'category': category,
        'barcode': barcode,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'stock': stock,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        shopId: json['shopId'],
        name: json['name'],
        category: json['category'] ?? 'General',
        barcode: json['barcode'] ?? '',
        costPrice: (json['costPrice'] as num).toDouble(),
        salePrice: (json['salePrice'] as num).toDouble(),
        stock: json['stock'],
      );
}
