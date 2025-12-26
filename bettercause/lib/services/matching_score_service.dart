import 'dart:math';
import '../models/user_preferences_model.dart';
import '../models/search_model.dart';
import '../models/matching_result_model.dart';

class MatchingScoreService {
  // ========================================================================
  // WEIGHT CONSTANTS (FROM SPECIFICATION)
  // ========================================================================
  static const double WEIGHT_PF = 0.35; // Personal Fit
  static const double WEIGHT_IC = 0.20; // Ingredient Compatibility
  static const double WEIGHT_HS = 0.20; // Health & Condition Safety
  static const double WEIGHT_EV = 0.15; // Ethical Values
  static const double WEIGHT_PQ = 0.10; // Product Quality

  // Data completeness thresholds
  static const double MIN_DATA_FOR_SCORE = 0.60;
  static const double MIN_DATA_FOR_FULL_CONFIDENCE = 0.75;

  // ========================================================================
  // MAIN CALCULATION METHOD
  // ========================================================================
  
  /// Calculate matching score between user preferences and product
  static MatchingResult calculateMatchingScore(
    UserPreferences userPrefs,
    Product product,
    Map<String, dynamic> productRawJson, // Need raw JSON for nutrient_levels
  ) {
    print('🔍 [MATCHING] Starting calculation...');
    print('🔍 [MATCHING] Product: ${product.name}');
    print('🔍 [MATCHING] User has preferences: ${userPrefs.hasPreferences}');
    print('🔍 [MATCHING] User has avoid list: ${userPrefs.hasAvoidList}');
    print('🔍 [MATCHING] User has health conditions: ${userPrefs.hasHealthConditions}');

    // Check data completeness first
    final completeness = _calculateDataCompleteness(product, productRawJson);
    print('🔍 [MATCHING] Data completeness: ${(completeness * 100).toStringAsFixed(1)}%');

    if (completeness < MIN_DATA_FOR_SCORE) {
      print('⚠️ [MATCHING] Insufficient data - returning breakdown only');
      return MatchingResult(
        totalScore: 0,
        category: 'Insufficient Data',
        breakdown: {},
        confidenceLabel: 'Product data incomplete',
        showScoreOnly: true,
      );
    }

    // Calculate individual scores
    final scores = <String, double>{};
    final weights = <String, double>{};

    // FACTOR 1: Personal Fit (PF)
    if (userPrefs.hasPreferences) {
      final pfScore = _calculatePersonalFit(userPrefs, product);
      scores['Personal Fit'] = pfScore;
      weights['Personal Fit'] = WEIGHT_PF;
      print('✅ [MATCHING] PF Score: ${pfScore.toStringAsFixed(1)}%');
    } else {
      print('⚠️ [MATCHING] Skipping PF - no user preferences');
    }

    // FACTOR 2: Ingredient Compatibility (IC)
    if (userPrefs.hasAvoidList) {
      final icScore = _calculateIngredientCompatibility(userPrefs, product);
      scores['Ingredient Compatibility'] = icScore;
      weights['Ingredient Compatibility'] = WEIGHT_IC;
      print('✅ [MATCHING] IC Score: ${icScore.toStringAsFixed(1)}%');
    } else {
      print('⚠️ [MATCHING] Skipping IC - no avoid list');
    }

    // FACTOR 3: Health & Condition Safety (HS)
    if (userPrefs.hasHealthConditions) {
      final hsScore = _calculateHealthSafety(userPrefs, productRawJson);
      scores['Health Safety'] = hsScore;
      weights['Health Safety'] = WEIGHT_HS;
      print('✅ [MATCHING] HS Score: ${hsScore.toStringAsFixed(1)}%');
    } else {
      print('⚠️ [MATCHING] Skipping HS - no health conditions');
    }

    // FACTOR 4: Ethical Values (EV)
    final nutrientLevels = productRawJson['nutrient_levels'] as Map<String, dynamic>?;
    final ecoScoreGrade = (productRawJson['ecoscore_grade'] ?? '').toString().toUpperCase();
    
    if (ecoScoreGrade.isNotEmpty && ecoScoreGrade != 'UNKNOWN') {
      final evScore = _calculateEthicalValues(ecoScoreGrade);
      scores['Ethical Values'] = evScore;
      weights['Ethical Values'] = WEIGHT_EV;
      print('✅ [MATCHING] EV Score: ${evScore.toStringAsFixed(1)}% (EcoScore: $ecoScoreGrade)');
    } else {
      print('⚠️ [MATCHING] Skipping EV - no EcoScore available');
    }

    // FACTOR 5: Product Quality (PQ)
    final pqScore = _calculateProductQuality(product);
    scores['Product Quality'] = pqScore;
    weights['Product Quality'] = WEIGHT_PQ;
    print('✅ [MATCHING] PQ Score: ${pqScore.toStringAsFixed(1)}%');

    // Redistribute weights if some factors are missing
    final adjustedWeights = _redistributeWeights(weights);
    print('🔍 [MATCHING] Adjusted weights: $adjustedWeights');

    // Calculate weighted total score
    double totalScore = 0;
    for (var entry in scores.entries) {
      final factor = entry.key;
      final score = entry.value;
      final weight = adjustedWeights[factor] ?? 0;
      final weightedScore = score * weight;
      totalScore += weightedScore;
      print('🔍 [MATCHING] $factor: $score × $weight = $weightedScore');
    }

    print('🎯 [MATCHING] TOTAL SCORE: ${totalScore.toStringAsFixed(1)}%');

    // Determine category
    final category = _categorizeScore(totalScore);
    print('🎯 [MATCHING] CATEGORY: $category');

    // Determine confidence label
    String? confidenceLabel;
    if (completeness < MIN_DATA_FOR_FULL_CONFIDENCE) {
      confidenceLabel = 'Low confidence - limited data';
      print('⚠️ [MATCHING] Low confidence warning added');
    }

    return MatchingResult(
      totalScore: totalScore,
      category: category,
      breakdown: scores,
      confidenceLabel: confidenceLabel,
      showScoreOnly: false,
    );
  }

  // ========================================================================
  // FACTOR 1: PERSONAL FIT (PF) - 35%
  // ========================================================================
  
  /// Formula: (Number of matching preference tags ÷ Total user preference tags) × 100
  static double _calculatePersonalFit(
    UserPreferences userPrefs,
    Product product,
  ) {
    if (userPrefs.preferenceTags.isEmpty) return 0;

    int matchCount = 0;
    
    print('🔍 [PF] User preference tags: ${userPrefs.preferenceTags}');
    print('🔍 [PF] Product idealFor tags: ${product.idealFor}');

    for (var userTag in userPrefs.preferenceTags) {
      final userTagLower = userTag.toLowerCase().trim();
      
      // Check exact matches and fuzzy matches
      for (var productTag in product.idealFor) {
        final productTagLower = productTag.toLowerCase().trim();
        
        // Direct match
        if (productTagLower == userTagLower) {
          matchCount++;
          print('✅ [PF] MATCH: "$userTag" = "$productTag"');
          break;
        }
        
        // Fuzzy matches for common variations
        if (_isFuzzyMatch(userTagLower, productTagLower)) {
          matchCount++;
          print('✅ [PF] FUZZY MATCH: "$userTag" ≈ "$productTag"');
          break;
        }
      }
    }

    final score = (matchCount / userPrefs.preferenceTags.length) * 100;
    print('🔍 [PF] Matched: $matchCount / ${userPrefs.preferenceTags.length}');
    return score;
  }

  /// Helper to match common variations (e.g., "Vegan Diet" → "Vegans")
  static bool _isFuzzyMatch(String userTag, String productTag) {
    // Remove common suffixes/prefixes
    final variations = [
      userTag,
      userTag.replaceAll(' diet', ''),
      userTag.replaceAll('diet', ''),
      userTag + 's',
      userTag.replaceAll('s', ''),
    ];
    
    return variations.any((v) => productTag.contains(v) || v.contains(productTag));
  }

  // ========================================================================
  // FACTOR 2: INGREDIENT COMPATIBILITY (IC) - 20%
  // ========================================================================
  
  /// Formula: 100 - (Avoided Ingredients Found ÷ Total Avoid List) × 100
  static double _calculateIngredientCompatibility(
    UserPreferences userPrefs,
    Product product,
  ) {
    if (userPrefs.avoidIngredients.isEmpty) return 100;

    int foundCount = 0;
    
    print('🔍 [IC] User avoids: ${userPrefs.avoidIngredients}');
    print('🔍 [IC] Product has ${product.ingredients.length} ingredients');

    for (var avoidIngredient in userPrefs.avoidIngredients) {
      final avoidLower = avoidIngredient.toLowerCase().trim();
      
      // Check if any product ingredient contains the avoided ingredient
      bool found = false;
      for (var productIng in product.ingredients) {
        final productIngLower = productIng.name.toLowerCase().trim();
        
        // Use .contains() for partial, case-insensitive matching
        if (productIngLower.contains(avoidLower)) {
          found = true;
          foundCount++;
          print('⚠️ [IC] FOUND AVOIDED: "$avoidIngredient" in "${productIng.name}"');
          break;
        }
      }
      
      if (!found) {
        print('✅ [IC] NOT FOUND: "$avoidIngredient"');
      }
    }

    final score = max(0.0, 100.0 - ((foundCount / userPrefs.avoidIngredients.length) * 100.0)).toDouble();
    print('🔍 [IC] Found avoided: $foundCount / ${userPrefs.avoidIngredients.length}');
    return score;
  }

  // ========================================================================
  // FACTOR 3: HEALTH & CONDITION SAFETY (HS) - 20%
  // ========================================================================
  
  /// Formula: 100 - (Nutrition risks found ÷ All generated nutrition risks) × 100
  static double _calculateHealthSafety(
    UserPreferences userPrefs,
    Map<String, dynamic> productRawJson,
  ) {
    // Generate nutrition risks based on health conditions
    final nutritionRisks = _generateNutritionRisks(userPrefs.healthConditions);
    
    if (nutritionRisks.isEmpty) {
      print('⚠️ [HS] No nutrition risks generated');
      return 100;
    }

    print('🔍 [HS] Generated risks: $nutritionRisks');

    // Get nutrient levels from API
    final nutrientLevels = productRawJson['nutrient_levels'] as Map<String, dynamic>?;
    
    if (nutrientLevels == null || nutrientLevels.isEmpty) {
      print('⚠️ [HS] No nutrient_levels data available');
      return 100;
    }

    print('🔍 [HS] Product nutrient levels: $nutrientLevels');

    int risksFound = 0;
    for (var risk in nutritionRisks) {
      if (_checkNutritionRisk(nutrientLevels, risk)) {
        risksFound++;
        print('⚠️ [HS] RISK FOUND: $risk');
      } else {
        print('✅ [HS] RISK NOT FOUND: $risk');
      }
    }

    final score = max(0.0, 100.0 - ((risksFound / nutritionRisks.length) * 100.0)).toDouble();
    print('🔍 [HS] Risks found: $risksFound / ${nutritionRisks.length}');
    return score;
  }

  /// Generate nutrition risks based on health conditions
  /// TODO: REPLACE WITH AI API CALL (OpenAI/Claude/Gemini)
  /// Current: Rule-based placeholder for common conditions
  static List<String> _generateNutritionRisks(List<String> healthConditions) {
    final risks = <String>{};
    
    print('🔍 [HS] Generating risks for conditions: $healthConditions');
    
    for (var condition in healthConditions) {
      final conditionLower = condition.toLowerCase().trim();
      
      // Diabetes-related
      if (conditionLower.contains('diabet')) {
        risks.addAll(['high_sugar', 'high_carbs']);
        print('🔍 [HS] Diabetic → added high_sugar, high_carbs');
      }
      
      // Hypertension / Blood Pressure
      if (conditionLower.contains('hypertension') || 
          conditionLower.contains('blood pressure') ||
          conditionLower.contains('high blood')) {
        risks.addAll(['high_salt', 'high_sodium']);
        print('🔍 [HS] Hypertension → added high_salt, high_sodium');
      }
      
      // Cholesterol / Heart Health
      if (conditionLower.contains('cholesterol') || 
          conditionLower.contains('heart')) {
        risks.addAll(['high_saturated_fat', 'high_fat']);
        print('🔍 [HS] Heart/Cholesterol → added high_saturated_fat, high_fat');
      }
      
      // Lactose Intolerance
      if (conditionLower.contains('lactose')) {
        risks.add('contains_dairy');
        print('🔍 [HS] Lactose intolerant → added contains_dairy');
      }
      
      // Celiac / Gluten
      if (conditionLower.contains('celiac') || 
          conditionLower.contains('gluten')) {
        risks.add('contains_gluten');
        print('🔍 [HS] Celiac/Gluten → added contains_gluten');
      }
      
      // Weight Management
      if (conditionLower.contains('weight') || 
          conditionLower.contains('obesity')) {
        risks.addAll(['high_fat', 'high_sugar']);
        print('🔍 [HS] Weight management → added high_fat, high_sugar');
      }
    }
    
    return risks.toList();
  }

  /// Check if product has a specific nutrition risk using API's nutrient_levels
  static bool _checkNutritionRisk(
    Map<String, dynamic> nutrientLevels,
    String risk,
  ) {
    // Map risk names to API's nutrient_levels keys
    final riskMapping = {
      'high_sugar': 'sugars',
      'high_carbs': 'carbohydrates',
      'high_salt': 'salt',
      'high_sodium': 'salt', // API uses 'salt' not 'sodium'
      'high_saturated_fat': 'saturated-fat',
      'high_fat': 'fat',
    };

    // Check if this is a "high_X" type risk
    if (risk.startsWith('high_')) {
      final nutrientKey = riskMapping[risk];
      if (nutrientKey == null) {
        print('⚠️ [HS] Unknown risk mapping: $risk');
        return false;
      }
      
      final level = nutrientLevels[nutrientKey]?.toString().toLowerCase();
      print('🔍 [HS] Checking $risk → nutrient: $nutrientKey, level: $level');
      
      // Risk is found if level is "high"
      return level == 'high';
    }
    
    // For specific ingredient risks (dairy, gluten), would need to check ingredients
    // For now, return false as these are not in nutrient_levels
    print('⚠️ [HS] Cannot check ingredient-based risk: $risk (requires ingredient analysis)');
    return false;
  }

  // ========================================================================
  // FACTOR 4: ETHICAL VALUES (EV) - 15%
  // ========================================================================
  
  /// Convert EcoScore grade to points
  /// A = 100, B = 80, C = 60, D = 40, E = 20
  static double _calculateEthicalValues(String ecoScoreGrade) {
    final scoreMap = {
      'A': 100.0,
      'B': 80.0,
      'C': 60.0,
      'D': 40.0,
      'E': 20.0,
    };

    return scoreMap[ecoScoreGrade.toUpperCase()] ?? 0;
  }

  // ========================================================================
  // FACTOR 5: PRODUCT QUALITY (PQ) - 10%
  // ========================================================================
  
  /// Based on NutriScore and certifications
  /// Formula: (NutriScore points + other certs × 100) ÷ total cert sources
  static double _calculateProductQuality(Product product) {
    double totalPoints = 0;
    int sources = 0;

    // NutriScore contribution
    if (product.nutritionScore.isNotEmpty && 
        product.nutritionScore.toUpperCase() != 'UNKNOWN') {
      final scoreMap = {
        'A': 100.0,
        'B': 80.0,
        'C': 60.0,
        'D': 40.0,
        'E': 20.0,
      };
      
      final nutriScorePoints = scoreMap[product.nutritionScore.toUpperCase()] ?? 0;
      totalPoints += nutriScorePoints;
      sources++;
      print('🔍 [PQ] NutriScore ${product.nutritionScore}: $nutriScorePoints points');
    }

    // Other certifications (exclude nutriscore and ecoscore from certifications list)
    int otherCertCount = 0;
    for (var cert in product.certifications) {
      final certLower = cert.toLowerCase();
      
      // Skip nutriscore and ecoscore as they're counted separately
      if (certLower.contains('nutriscore') || certLower.contains('ecoscore')) {
        continue;
      }
      
      otherCertCount++;
      print('🔍 [PQ] Certification found: $cert');
    }

    if (otherCertCount > 0) {
      totalPoints += otherCertCount * 100; // Each cert adds 100 points
      sources += otherCertCount;
      print('🔍 [PQ] Other certifications: $otherCertCount × 100 = ${otherCertCount * 100} points');
    }

    if (sources == 0) {
      print('⚠️ [PQ] No quality indicators available');
      return 0;
    }

    final score = totalPoints / sources;
    print('🔍 [PQ] Total: $totalPoints ÷ $sources = $score');
    return score;
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Calculate data completeness (0.0 to 1.0)
  static double _calculateDataCompleteness(
    Product product,
    Map<String, dynamic> productRawJson,
  ) {
    int totalFields = 6;
    int presentFields = 0;

    // 1. Has name
    if (product.name.isNotEmpty && product.name != 'Unknown product') {
      presentFields++;
    }

    // 2. Has brand
    if (product.brand.isNotEmpty && product.brand != 'Unknown brand') {
      presentFields++;
    }

    // 3. Has NutriScore
    if (product.nutritionScore.isNotEmpty && 
        product.nutritionScore.toUpperCase() != 'UNKNOWN') {
      presentFields++;
    }

    // 4. Has EcoScore
    final ecoScore = productRawJson['ecoscore_grade']?.toString() ?? '';
    if (ecoScore.isNotEmpty && ecoScore.toUpperCase() != 'UNKNOWN') {
      presentFields++;
    }

    // 5. Has ingredients (at least 3)
    if (product.ingredients.length >= 3) {
      presentFields++;
    }

    // 6. Has nutrient_levels (at least 2)
    final nutrientLevels = productRawJson['nutrient_levels'] as Map<String, dynamic>?;
    if (nutrientLevels != null && nutrientLevels.length >= 2) {
      presentFields++;
    }

    return presentFields / totalFields;
  }

  /// Redistribute weights when some factors are missing
  static Map<String, double> _redistributeWeights(Map<String, double> weights) {
    if (weights.isEmpty) return {};

    final totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
    final adjustedWeights = <String, double>{};

    for (var entry in weights.entries) {
      adjustedWeights[entry.key] = entry.value / totalWeight;
    }

    return adjustedWeights;
  }

  /// Categorize score into human-readable categories
  static String _categorizeScore(double score) {
    if (score >= 90) return 'Great';
    if (score >= 75) return 'Good';
    if (score >= 50) return 'Moderate';
    if (score >= 25) return 'Poor';
    return 'Very Poor';
  }
}