// lib/models/search_model.dart

class Product {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final String category;
  final String nutritionScore;
  final double price;
  final DateTime addedDate;

  // Detail fields
  final bool isVegan;
  final bool isEcoFriendly;
  final int matchPercentage;
  final String description;
  final List<String> idealFor;
  final int calories;
  final double protein;
  final double fat;
  final int ethicsScore;
  final String environmentalImpact;
  final String animalWelfare;
  final String fairLabor;
  final List<ProductIngredient> ingredients;
  final List<ProductNutrient> positives;
  final List<ProductNutrient> negatives;
  final List<String> certifications;
  final List<Product> alternatives;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.category,
    required this.nutritionScore,
    required this.price,
    required this.addedDate,
    this.isVegan = false,
    this.isEcoFriendly = false,
    this.matchPercentage = 0,
    this.description = '',
    this.idealFor = const [],
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.ethicsScore = 0,
    this.environmentalImpact = 'N/A',
    this.animalWelfare = 'N/A',
    this.fairLabor = 'N/A',
    this.ingredients = const [],
    this.positives = const [],
    this.negatives = const [],
    this.certifications = const [],
    this.alternatives = const [],
  });

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? imageUrl,
    String? category,
    String? nutritionScore,
    double? price,
    DateTime? addedDate,
    bool? isVegan,
    bool? isEcoFriendly,
    int? matchPercentage,
    String? description,
    List<String>? idealFor,
    int? calories,
    double? protein,
    double? fat,
    int? ethicsScore,
    String? environmentalImpact,
    String? animalWelfare,
    String? fairLabor,
    List<ProductIngredient>? ingredients,
    List<ProductNutrient>? positives,
    List<ProductNutrient>? negatives,
    List<String>? certifications,
    List<Product>? alternatives,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      price: price ?? this.price,
      addedDate: addedDate ?? this.addedDate,
      isVegan: isVegan ?? this.isVegan,
      isEcoFriendly: isEcoFriendly ?? this.isEcoFriendly,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      description: description ?? this.description,
      idealFor: idealFor ?? this.idealFor,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      ethicsScore: ethicsScore ?? this.ethicsScore,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      animalWelfare: animalWelfare ?? this.animalWelfare,
      fairLabor: fairLabor ?? this.fairLabor,
      ingredients: ingredients ?? this.ingredients,
      positives: positives ?? this.positives,
      negatives: negatives ?? this.negatives,
      certifications: certifications ?? this.certifications,
      alternatives: alternatives ?? this.alternatives,
    );
  }

  /// Old local JSON mapping (keep if you still need it)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      nutritionScore: json['nutritionScore'] as String,
      price: (json['price'] as num).toDouble(),
      addedDate: DateTime.parse(json['addedDate'] as String),
      isVegan: json['isVegan'] as bool? ?? false,
      isEcoFriendly: json['isEcoFriendly'] as bool? ?? false,
      matchPercentage: json['matchPercentage'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      idealFor: (json['idealFor'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      ethicsScore: json['ethicsScore'] as int? ?? 0,
      environmentalImpact: json['environmentalImpact'] as String? ?? 'N/A',
      animalWelfare: json['animalWelfare'] as String? ?? 'N/A',
      fairLabor: json['fairLabor'] as String? ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'category': category,
      'nutritionScore': nutritionScore,
      'price': price,
      'addedDate': addedDate.toIso8601String(),
      'isVegan': isVegan,
      'isEcoFriendly': isEcoFriendly,
      'matchPercentage': matchPercentage,
      'description': description,
      'idealFor': idealFor,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'ethicsScore': ethicsScore,
      'environmentalImpact': environmentalImpact,
      'animalWelfare': animalWelfare,
      'fairLabor': fairLabor,
    };
  }

  /// NEW: Build from Open Food Facts product JSON
  factory Product.fromOpenFoodFacts(Map<String, dynamic> json) {
    // ID / code
    final String id = (json['id'] ?? json['code'] ?? '').toString();

    // Name
    final String name = (json['product_name'] ??
            json['product_name_en'] ??
            'Unknown product')
        .toString()
        .trim();

    // Brand (first brand only)
    String brand = (json['brands'] ?? '').toString().trim();
    if (brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }
    if (brand.isEmpty) brand = 'Unknown brand';

    // Image
    String imageUrl =
        (json['image_front_url'] ?? json['image_url'] ?? '').toString();
    if (imageUrl.isEmpty) {
      final selected =
          json['selected_images']?['front']?['display']?['en']?.toString();
      if (selected != null) {
        imageUrl = selected;
      }
    }

    // NutriScore
    String score = (json['nutriscore_grade'] ?? '').toString();
    if (score.isNotEmpty && score != 'unknown') {
      score = score.toUpperCase(); // "a" -> "A"
    } else {
      score = ''; // will render as grey bars
    }

    // Very rough category mapping for emoji & filters
    final List<dynamic> categoriesTags =
        (json['categories_tags'] as List<dynamic>? ?? []);
    final String category = _mapOffCategoriesToAppCategory(categoriesTags);

    // Nutriments
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};
    final int calories = _toInt(nutriments['energy-kcal_100g'] ??
        nutriments['energy-kcal_serving'] ??
        nutriments['energy-kcal']);
    final double protein =
        _toDouble(nutriments['proteins_100g'] ?? nutriments['proteins_serving']);
    final double fat =
        _toDouble(nutriments['fat_100g'] ?? nutriments['fat_serving']);

    // Added / modified date
    final int lastModified = _toInt(json['last_modified_t'] ?? json['created_t']);
    final addedDate = lastModified > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastModified * 1000)
        : DateTime.now();

    // Very rough vegan detection (optional)
    final List<dynamic> labelsTags =
        (json['labels_tags'] as List<dynamic>? ?? []);
    final List<dynamic> ingredientsAnalysis =
        (json['ingredients_analysis_tags'] as List<dynamic>? ?? []);
    final bool isVegan =
        labelsTags.contains('en:vegan') || ingredientsAnalysis.contains('en:vegan');

    return Product(
      id: id.isEmpty ? 'unknown' : id,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      category: category,
      nutritionScore: score,
      price: 0.0, // OFF doesn't give price
      addedDate: addedDate,
      isVegan: isVegan,
      isEcoFriendly: false, // we can improve later using ecoscore
      matchPercentage: 0, // later your AI can compute this
      description: json['generic_name_en']?.toString() ?? '',
      idealFor: const [],
      calories: calories,
      protein: protein,
      fat: fat,
      ethicsScore: 0,
      environmentalImpact: 'N/A',
      animalWelfare: 'N/A',
      fairLabor: 'N/A',
      ingredients: const [],
      positives: const [],
      negatives: const [],
      certifications: const [],
      alternatives: const [],
    );
  }

  static String _mapOffCategoriesToAppCategory(List<dynamic> tags) {
    final lowerTags = tags.map((e) => e.toString().toLowerCase()).toList();

    bool containsAny(List<String> needles) =>
        lowerTags.any((t) => needles.any((n) => t.contains(n)));

    if (containsAny(['beverages', 'drinks', 'juices', 'sodas'])) {
      return 'beverages';
    }
    if (containsAny(['chocolate', 'sweets', 'confectionery', 'biscuits'])) {
      return 'sweets';
    }
    if (containsAny(['dairies', 'cheeses', 'milk-products', 'yogurts'])) {
      return 'dairy';
    }
    if (containsAny(['dietary-supplements', 'vitamins', 'food-supplements'])) {
      return 'supplements';
    }
    return 'unknown';
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class ProductIngredient {
  final String name;
  final String status; // 'reduced', 'monitored', etc.
  final List<String> subIngredients;

  ProductIngredient({
    required this.name,
    required this.status,
    this.subIngredients = const [],
  });
}

class ProductNutrient {
  final String name;
  final String icon;
  final String value;
  final bool hasInfo;
  final List<String>? details;

  ProductNutrient({
    required this.name,
    required this.icon,
    required this.value,
    this.hasInfo = true,
    this.details,
  });
}
