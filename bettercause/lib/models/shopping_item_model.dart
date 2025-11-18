class ShoppingItem {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final String category;
  final bool isBought;
  final DateTime addedDate;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.category,
    required this.isBought,
    required this.addedDate,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? imageUrl,
    String? category,
    bool? isBought,
    DateTime? addedDate,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isBought: isBought ?? this.isBought,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      isBought: json['isBought'] as bool,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'category': category,
      'isBought': isBought,
      'addedDate': addedDate.toIso8601String(),
    };
  }
}