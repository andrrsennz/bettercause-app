// lib/models/shopping_item_model.dart

class ShoppingItem {
  final String id;          // OFF barcode OR manual id
  final String name;
  final String brand;
  final String imageUrl;
  final String category;    // Food & Beverages / Beauty & Care / Household / Electronics
  final bool isBought;
  final DateTime addedDate;

  const ShoppingItem({
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

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "brand": brand,
      "imageUrl": imageUrl,
      "category": category,
      "isBought": isBought,
      "addedDate": addedDate.toIso8601String(),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      brand: (json["brand"] ?? "").toString(),
      imageUrl: (json["imageUrl"] ?? "").toString(),
      category: (json["category"] ?? "Food & Beverages").toString(),
      isBought: (json["isBought"] ?? false) == true,
      addedDate: DateTime.tryParse((json["addedDate"] ?? "").toString()) ??
          DateTime.now(),
    );
  }
}
