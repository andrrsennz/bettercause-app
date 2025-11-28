class UserProfile {
  final String name;
  final String memberSince;
  final int productScans;
  final int productsPurchased;
  final Map<String, bool> personalValues;
  final CategoryPreferences categoryPreferences;

  UserProfile({
    required this.name,
    required this.memberSince,
    required this.productScans,
    required this.productsPurchased,
    required this.personalValues,
    required this.categoryPreferences,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      memberSince: json['memberSince'] ?? '',
      productScans: json['productScans'] ?? 0,
      productsPurchased: json['productsPurchased'] ?? 0,
      personalValues: Map<String, bool>.from(json['personalValues'] ?? {}),
      categoryPreferences: CategoryPreferences.fromJson(
        json['categoryPreferences'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'memberSince': memberSince,
      'productScans': productScans,
      'productsPurchased': productsPurchased,
      'personalValues': personalValues,
      'categoryPreferences': categoryPreferences.toJson(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? memberSince,
    int? productScans,
    int? productsPurchased,
    Map<String, bool>? personalValues,
    CategoryPreferences? categoryPreferences,
  }) {
    return UserProfile(
      name: name ?? this.name,
      memberSince: memberSince ?? this.memberSince,
      productScans: productScans ?? this.productScans,
      productsPurchased: productsPurchased ?? this.productsPurchased,
      personalValues: personalValues ?? this.personalValues,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
    );
  }
}

class CategoryPreferences {
  final Map<String, int> preferencesCount;

  CategoryPreferences({
    required this.preferencesCount,
  });

  factory CategoryPreferences.fromJson(Map<String, dynamic> json) {
    return CategoryPreferences(
      preferencesCount: Map<String, int>.from(json['preferencesCount'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferencesCount': preferencesCount,
    };
  }
}