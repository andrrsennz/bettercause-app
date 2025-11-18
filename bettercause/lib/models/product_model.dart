class Product {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final DateTime? purchaseDate;
  final DateTime? scanDate;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.purchaseDate,
    this.scanDate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      imageUrl: json['imageUrl'] as String,
      purchaseDate: json['purchaseDate'] != null 
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      scanDate: json['scanDate'] != null
          ? DateTime.parse(json['scanDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'scanDate': scanDate?.toIso8601String(),
    };
  }
}