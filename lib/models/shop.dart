class Shop {
  final String id;
  final String ownerId;
  final String name;

  Shop({
    required this.id,
    required this.ownerId,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
      };

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'],
        ownerId: json['ownerId'],
        name: json['name'],
      );
}
