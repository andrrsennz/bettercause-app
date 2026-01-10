// lib/models/purchase_record_model.dart

class PurchaseRecord {
  final String productId;         // OFF barcode id
  final DateTime purchasedAt;      // when tracked
  final String? marketplace;       // shopee / tokopedia / null (manual)
  final String? experience;        // GREAT / AVERAGE / BAD / null

  const PurchaseRecord({
    required this.productId,
    required this.purchasedAt,
    this.marketplace,
    this.experience,
  });

  PurchaseRecord copyWith({
    String? productId,
    DateTime? purchasedAt,
    String? marketplace,
    String? experience,
  }) {
    return PurchaseRecord(
      productId: productId ?? this.productId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      marketplace: marketplace ?? this.marketplace,
      experience: experience ?? this.experience,
    );
  }

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "purchasedAt": purchasedAt.toIso8601String(),
        "marketplace": marketplace,
        "experience": experience,
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      productId: (json["productId"] ?? "").toString(),
      purchasedAt: DateTime.tryParse((json["purchasedAt"] ?? "").toString()) ??
          DateTime.now(),
      marketplace: json["marketplace"]?.toString(),
      experience: json["experience"]?.toString(),
    );
  }
}
