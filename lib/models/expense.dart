class Expense {
  final String id;
  final String shopId;
  final String category;
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.shopId,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        shopId: json['shopId'],
        category: json['category'],
        description: json['description'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );
}
