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
  final Map<String, dynamic>? rawApiData;
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
    this.rawApiData,
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
    Map<String, dynamic>? rawApiData,
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
      rawApiData: rawApiData ?? this.rawApiData,
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

  /// NEW: Build from Open Food Facts product JSON using API v2
  /// This properly extracts nutrient_levels, additives, and all quality indicators
  factory Product.fromOpenFoodFacts(Map<String, dynamic> json) {
    // ========= BASIC INFO =========
    final String id = (json['id'] ?? json['code'] ?? '').toString();

    final String name = (json['product_name'] ??
            json['product_name_en'] ??
            'Unknown product')
        .toString()
        .trim();

    String brand = (json['brands'] ?? '').toString().trim();
    if (brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }
    if (brand.isEmpty) brand = 'Unknown brand';

    // Image - prioritize high quality
    String imageUrl = '';
    if (json['selected_images'] != null && json['selected_images']['front'] != null) {
      imageUrl = (json['selected_images']['front']['display']?['en'] ?? 
                 json['selected_images']['front']['display']?['fr'] ?? 
                 json['selected_images']['front']['small']?['en'] ?? '').toString();
    }
    if (imageUrl.isEmpty) {
      imageUrl = (json['image_front_url'] ?? json['image_url'] ?? '').toString();
    }

    // ========= SCORES =========
    String score = (json['nutriscore_grade'] ?? '').toString();
    if (score.isNotEmpty && score != 'unknown') {
      score = score.toUpperCase();
    } else {
      score = '';
    }

    final String ecoScoreGrade = (json['ecoscore_grade'] ?? '').toString().toUpperCase();
    final bool isEcoFriendly = ['A', 'B'].contains(ecoScoreGrade);

    // ========= CATEGORY =========
    final List<dynamic> categoriesTags = (json['categories_tags'] as List<dynamic>? ?? []);
    final String category = _mapOffCategoriesToAppCategory(categoriesTags);

    // ========= NUTRIMENTS (per 100g) =========
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};
    final int calories = _toInt(nutriments['energy-kcal_100g']);
    final double protein = _toDouble(nutriments['proteins_100g']);
    final double fat = _toDouble(nutriments['fat_100g']);
    final double sugar = _toDouble(nutriments['sugars_100g']);
    final double sodium = _toDouble(nutriments['sodium_100g']); // in mg
    final double fiber = _toDouble(nutriments['fiber_100g']);
    final double saturatedFat = _toDouble(nutriments['saturated-fat_100g']);
    final double salt = _toDouble(nutriments['salt_100g']); // in g

    // ========= NUTRIENT LEVELS (FROM API - the key to good vs bad) =========
    final nutrientLevels = json['nutrient_levels'] as Map<String, dynamic>? ?? {};
    // Possible values: "low", "moderate", "high"

    // ========= LABELS & CERTIFICATIONS =========
    final List<dynamic> labelsTags = (json['labels_tags'] as List<dynamic>? ?? []);
    final List<dynamic> ingredientsAnalysis = (json['ingredients_analysis_tags'] as List<dynamic>? ?? []);
    
    final bool isVegan = labelsTags.contains('en:vegan') || ingredientsAnalysis.contains('en:vegan');
    final bool isVegetarian = labelsTags.contains('en:vegetarian') || ingredientsAnalysis.contains('en:vegetarian');
    final bool isPalmOilFree = ingredientsAnalysis.contains('en:palm-oil-free');

    // ========= ADDITIVES (FROM API) =========
    final List<dynamic> additivesTags = json['additives_tags'] as List<dynamic>? ?? [];
    final int additivesN = _toInt(json['additives_n']);

    // ========= NOVA GROUP (Ultra-processing) =========
    final int novaGroup = _toInt(json['nova_group']);
    // 1 = unprocessed, 2 = processed ingredients, 3 = processed, 4 = ultra-processed

    // ========= INGREDIENTS =========
    final List<ProductIngredient> ingredients = [];
    final List<dynamic> ingredientsList = json['ingredients'] as List<dynamic>? ?? [];
    
    for (var ing in ingredientsList.take(15)) {
      if (ing is Map<String, dynamic>) {
        final ingText = (ing['text'] ?? ing['id'] ?? '').toString().trim();
        if (ingText.isEmpty) continue;
        
        String status = 'normal';
        
        // Check vegan/vegetarian status
        if (ing['vegan'] == 'no' || ing['vegetarian'] == 'no') {
          status = 'reduced';
        } else if (ing['vegan'] == 'maybe' || ing['vegetarian'] == 'maybe') {
          status = 'monitored';
        }
        
        // Check if it's an additive
        if (ingText.toLowerCase().startsWith('e') && 
            RegExp(r'e[0-9]').hasMatch(ingText.toLowerCase())) {
          status = 'monitored';
        }
        
        ingredients.add(ProductIngredient(
          name: ingText,
          status: status,
          subIngredients: const [],
        ));
      }
    }

    // ========= BUILD POSITIVES (FROM API DATA) =========
    final List<ProductNutrient> positives = [];

    // Low nutrient levels (good)
    if (nutrientLevels['fat'] == 'low') {
      positives.add(ProductNutrient(
        name: 'Low Fat',
        icon: '✓',
        value: '${fat.toStringAsFixed(1)}g per 100g',
      ));
    }
    
    if (nutrientLevels['saturated-fat'] == 'low') {
      positives.add(ProductNutrient(
        name: 'Low Saturated Fat',
        icon: '✓',
        value: '${saturatedFat.toStringAsFixed(1)}g per 100g',
      ));
    }
    
    if (nutrientLevels['sugars'] == 'low') {
      positives.add(ProductNutrient(
        name: 'Low Sugar',
        icon: '✓',
        value: '${sugar.toStringAsFixed(1)}g per 100g',
      ));
    }
    
    if (nutrientLevels['salt'] == 'low') {
      positives.add(ProductNutrient(
        name: 'Low Salt',
        icon: '✓',
        value: '${salt.toStringAsFixed(2)}g per 100g',
      ));
    }

    // High fiber (good)
    if (fiber >= 6.0) {
      positives.add(ProductNutrient(
        name: 'High Fiber',
        icon: '🌾',
        value: '${fiber.toStringAsFixed(1)}g per 100g',
      ));
    } else if (fiber >= 3.0) {
      positives.add(ProductNutrient(
        name: 'Source of Fiber',
        icon: '🌾',
        value: '${fiber.toStringAsFixed(1)}g per 100g',
      ));
    }

    // High protein (good)
    if (protein >= 12.0) {
      positives.add(ProductNutrient(
        name: 'High Protein',
        icon: '💪',
        value: '${protein.toStringAsFixed(1)}g per 100g',
      ));
    } else if (protein >= 6.0) {
      positives.add(ProductNutrient(
        name: 'Source of Protein',
        icon: '💪',
        value: '${protein.toStringAsFixed(1)}g per 100g',
      ));
    }

    // Dietary preferences
    if (isVegan) {
      positives.add(ProductNutrient(
        name: 'Vegan',
        icon: '🌱',
        value: 'Certified',
      ));
    } else if (isVegetarian) {
      positives.add(ProductNutrient(
        name: 'Vegetarian',
        icon: '🥬',
        value: 'Certified',
      ));
    }

    if (isPalmOilFree) {
      positives.add(ProductNutrient(
        name: 'Palm Oil Free',
        icon: '🌴',
        value: 'Yes',
      ));
    }

    // Certifications
    if (labelsTags.contains('en:organic') || labelsTags.contains('en:eu-organic')) {
      positives.add(ProductNutrient(
        name: 'Organic',
        icon: '🍃',
        value: 'Certified',
      ));
    }

    if (labelsTags.contains('en:fair-trade')) {
      positives.add(ProductNutrient(
        name: 'Fair Trade',
        icon: '⚖️',
        value: 'Certified',
      ));
    }

    // No or few additives
    if (additivesN == 0) {
      positives.add(ProductNutrient(
        name: 'No Additives',
        icon: '✓',
        value: 'Clean Label',
      ));
    }

    // Minimal processing
    if (novaGroup <= 2) {
      positives.add(ProductNutrient(
        name: 'Minimally Processed',
        icon: '✓',
        value: 'NOVA Group $novaGroup',
      ));
    }

    // ========= BUILD NEGATIVES (FROM API DATA) =========
    final List<ProductNutrient> negatives = [];

    // High nutrient levels (bad)
    if (nutrientLevels['fat'] == 'high') {
      negatives.add(ProductNutrient(
        name: 'High Fat',
        icon: '⚠️',
        value: '${fat.toStringAsFixed(1)}g per 100g',
        details: ['Exceeds 17.5g per 100g'],
      ));
    } else if (nutrientLevels['fat'] == 'moderate') {
      negatives.add(ProductNutrient(
        name: 'Moderate Fat',
        icon: '⚠️',
        value: '${fat.toStringAsFixed(1)}g per 100g',
        details: ['Between 3g and 17.5g per 100g'],
      ));
    }
    
    if (nutrientLevels['saturated-fat'] == 'high') {
      negatives.add(ProductNutrient(
        name: 'High Saturated Fat',
        icon: '⚠️',
        value: '${saturatedFat.toStringAsFixed(1)}g per 100g',
        details: ['Exceeds 5g per 100g', 'May increase cholesterol'],
      ));
    } else if (nutrientLevels['saturated-fat'] == 'moderate') {
      negatives.add(ProductNutrient(
        name: 'Moderate Saturated Fat',
        icon: '⚠️',
        value: '${saturatedFat.toStringAsFixed(1)}g per 100g',
        details: ['Between 1.5g and 5g per 100g'],
      ));
    }
    
    if (nutrientLevels['sugars'] == 'high') {
      negatives.add(ProductNutrient(
        name: 'High Sugar',
        icon: '⚠️',
        value: '${sugar.toStringAsFixed(1)}g per 100g',
        details: ['Exceeds 22.5g per 100g'],
      ));
    } else if (nutrientLevels['sugars'] == 'moderate') {
      negatives.add(ProductNutrient(
        name: 'Moderate Sugar',
        icon: '⚠️',
        value: '${sugar.toStringAsFixed(1)}g per 100g',
        details: ['Between 5g and 22.5g per 100g'],
      ));
    }
    
    if (nutrientLevels['salt'] == 'high') {
      negatives.add(ProductNutrient(
        name: 'High Salt',
        icon: '⚠️',
        value: '${salt.toStringAsFixed(2)}g per 100g',
        details: ['Exceeds 1.5g per 100g'],
      ));
    } else if (nutrientLevels['salt'] == 'moderate') {
      negatives.add(ProductNutrient(
        name: 'Moderate Salt',
        icon: '⚠️',
        value: '${salt.toStringAsFixed(2)}g per 100g',
        details: ['Between 0.3g and 1.5g per 100g'],
      ));
    }

    // Additives
    if (additivesN > 0) {
      final List<String> additiveDetails = [];
      for (var additive in additivesTags.take(5)) {
        String additiveName = additive.toString()
            .replaceAll('en:', '')
            .replaceAll('-', ' ')
            .split(':')
            .last
            .trim();
        if (additiveName.isNotEmpty) {
          additiveDetails.add(additiveName);
        }
      }
      
      negatives.add(ProductNutrient(
        name: additivesN == 1 ? 'Contains Additive' : 'Contains Additives',
        icon: '⚠️',
        value: '$additivesN found',
        details: additiveDetails.isNotEmpty ? additiveDetails : null,
      ));
    }

    // Palm oil
    if (ingredientsAnalysis.contains('en:palm-oil')) {
      negatives.add(ProductNutrient(
        name: 'Contains Palm Oil',
        icon: '🌴',
        value: 'Yes',
        details: ['Associated with deforestation'],
      ));
    }

    // Ultra-processed
    if (novaGroup == 4) {
      negatives.add(ProductNutrient(
        name: 'Ultra-Processed',
        icon: '⚠️',
        value: 'NOVA Group 4',
        details: ['Highly processed food product'],
      ));
    }

    // ========= DESCRIPTION =========
    String description = (json['generic_name_en'] ?? json['generic_name'] ?? '').toString();
    if (description.isEmpty) {
      description = (json['categories'] ?? '').toString();
    }
    if (description.isEmpty) {
      description = 'Product from Open Food Facts database';
    }

    // ========= CERTIFICATIONS =========
    final List<String> certifications = [];
    if (score.isNotEmpty) certifications.add('nutriscore-${score.toLowerCase()}');
    if (ecoScoreGrade.isNotEmpty) certifications.add('ecoscore-${ecoScoreGrade.toLowerCase()}');
    if (labelsTags.contains('en:organic') || labelsTags.contains('en:eu-organic')) {
      certifications.add('organic');
    }
    if (labelsTags.contains('en:fair-trade')) certifications.add('fair-trade');
    if (labelsTags.contains('en:gluten-free')) certifications.add('gluten-free');
    if (isVegan) certifications.add('vegan');
    if (labelsTags.contains('en:palm-oil-free')) certifications.add('palm-oil-free');

    // ========= ETHICS SCORE (0-100) =========
    int ethicsScore = 50;
    
    // Eco score impact
    switch (ecoScoreGrade) {
      case 'A': ethicsScore += 20; break;
      case 'B': ethicsScore += 10; break;
      case 'D': ethicsScore -= 10; break;
      case 'E': ethicsScore -= 20; break;
    }
    
    // Dietary ethics
    if (isVegan) ethicsScore += 15;
    else if (isVegetarian) ethicsScore += 10;
    
    // Labor & production ethics
    if (labelsTags.contains('en:fair-trade')) ethicsScore += 15;
    if (labelsTags.contains('en:organic')) ethicsScore += 10;
    
    // Environmental concerns
    if (!isPalmOilFree && ingredientsAnalysis.contains('en:palm-oil')) ethicsScore -= 15;
    if (additivesN > 5) ethicsScore -= 5;
    if (novaGroup == 4) ethicsScore -= 5;
    
    ethicsScore = ethicsScore.clamp(0, 100);

    // ========= ENVIRONMENTAL IMPACT =========
    String environmentalImpact = 'N/A';
    if (ecoScoreGrade.isNotEmpty) {
      switch (ecoScoreGrade) {
        case 'A': environmentalImpact = 'Very Low Impact'; break;
        case 'B': environmentalImpact = 'Low Impact'; break;
        case 'C': environmentalImpact = 'Moderate Impact'; break;
        case 'D': environmentalImpact = 'High Impact'; break;
        case 'E': environmentalImpact = 'Very High Impact'; break;
      }
    }

    // ========= ANIMAL WELFARE =========
    String animalWelfare = 'N/A';
    if (isVegan) {
      animalWelfare = 'Excellent - No Animal Products';
    } else if (isVegetarian) {
      animalWelfare = 'Good - No Meat';
    } else if (categoriesTags.any((c) {
      final tag = c.toString().toLowerCase();
      return tag.contains('meat') || tag.contains('fish') || 
             tag.contains('seafood') || tag.contains('poultry');
    })) {
      animalWelfare = 'Contains Animal Products';
    }

    // ========= FAIR LABOR =========
    String fairLabor = 'N/A';
    if (labelsTags.contains('en:fair-trade')) {
      fairLabor = 'Fair Trade Certified';
    }

    // ========= IDEAL FOR =========
    final List<String> idealFor = [];
    if (isVegan) idealFor.add('Vegans');
    if (isVegetarian && !isVegan) idealFor.add('Vegetarians');
    if (nutrientLevels['sugars'] == 'low') idealFor.add('Low Sugar Diet');
    if (fiber >= 6.0) idealFor.add('High Fiber Diet');
    if (protein >= 12.0) idealFor.add('High Protein Diet');
    if (nutrientLevels['salt'] == 'low') idealFor.add('Low Sodium Diet');
    if (labelsTags.contains('en:gluten-free')) idealFor.add('Gluten-Free');
    if (labelsTags.contains('en:lactose-free')) idealFor.add('Lactose-Free');
    if (novaGroup <= 2) idealFor.add('Whole Food Diet');

    // ========= DATE =========
    final int lastModified = _toInt(json['last_modified_t'] ?? json['created_t']);
    final addedDate = lastModified > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastModified * 1000)
        : DateTime.now();

    return Product(
      id: id.isEmpty ? 'unknown' : id,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      category: category,
      nutritionScore: score,
      price: 0.0,
      addedDate: addedDate,
      isVegan: isVegan,
      isEcoFriendly: isEcoFriendly,
      matchPercentage: 0,
      description: description,
      idealFor: idealFor,
      calories: calories,
      protein: protein,
      fat: fat,
      ethicsScore: ethicsScore,
      environmentalImpact: environmentalImpact,
      animalWelfare: animalWelfare,
      fairLabor: fairLabor,
      ingredients: ingredients,
      positives: positives,
      negatives: negatives,
      certifications: certifications,
      alternatives: const [],
      rawApiData: json,
    );
  }

  static String _mapOffCategoriesToAppCategory(List<dynamic> tags) {
    final lowerTags = tags.map((e) => e.toString().toLowerCase()).toList();

    bool containsAny(List<String> needles) =>
        lowerTags.any((t) => needles.any((n) => t.contains(n)));

    if (containsAny(['beverages', 'drinks', 'juices', 'sodas'])) {
      return 'beverages';
    }
    if (containsAny(['chocolate', 'sweets', 'confectionery', 'biscuits', 'candies'])) {
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
  final String status; // 'reduced', 'monitored', 'normal'
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