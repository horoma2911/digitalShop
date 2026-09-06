class Sale {
  final String id;
  final String shopId;
  final String productId;
  final String productName;
  final int quantity;
  final double totalPrice;
  final double profit;
  final DateTime date;

  Sale({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.profit,
    required this.date,
  });

  Sale copyWith({
    String? id,
    String? shopId,
    String? productId,
    String? productName,
    int? quantity,
    double? totalPrice,
    double? profit,
    DateTime? date,
  }) {
    return Sale(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      profit: profit ?? this.profit,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'profit': profit,
        'date': date.toIso8601String(),
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'],
        shopId: json['shopId'],
        productId: json['productId'],
        productName: json['productName'],
        quantity: json['quantity'],
        totalPrice: json['totalPrice'],
        profit: json['profit'],
        date: DateTime.parse(json['date']),
      );
}
