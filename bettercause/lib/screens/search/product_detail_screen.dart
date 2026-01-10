import 'package:flutter/material.dart';
import '../../models/search_model.dart';
import '../../services/search_service.dart';
import '../../services/product_history_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/matching_score_service.dart';
import '../../models/user_preferences_model.dart';
import '../../models/matching_result_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:convert'; // Add this if not already there
import 'package:http/http.dart' as http;
import '../../services/shopping_list_service.dart';
import '../../services/purchase_history_service.dart';


class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with WidgetsBindingObserver {

  final SearchService _service = SearchService();
  Product? _product;
  bool _isLoading = true;
  final ProductHistoryService _history = ProductHistoryService();
  final ShoppingListService _shoppingListService = ShoppingListService();

  final PurchaseHistoryService _purchaseHistoryService = PurchaseHistoryService();
  bool _didShowReturnModal = false;

  final Gemini gemini = Gemini.instance;
  bool _isLoadingAI = false;
  String _aiAnalysis = '';
  String? _aiError;

  // Add these after your existing state variables
String _aiVerdict = ''; // Will be 'RECOMMENDED', 'BUY WITH CAUTION', or 'NOT RECOMMENDED'
Color _getVerdictColor(String verdict) {
  switch (verdict.toUpperCase()) {
    case 'RECOMMENDED':
      return const Color(0xFF4CAF50); // Green
    case 'BUY WITH CAUTION':
      return const Color(0xFFFFA726); // Orange
    case 'NOT RECOMMENDED':
      return const Color(0xFFFF4444); // Red
    default:
      return const Color(0xFF6B4CE6); // Purple (analyzing)
  }
}

IconData _getVerdictIcon(String verdict) {
  switch (verdict.toUpperCase()) {
    case 'RECOMMENDED':
      return Icons.check_circle;
    case 'BUY WITH CAUTION':
      return Icons.warning;
    case 'NOT RECOMMENDED':
      return Icons.cancel;
    default:
      return Icons.psychology;
  }
}

  final ProfileService _profileService = ProfileService();
  final _storage = const FlutterSecureStorage();
  MatchingResult? _matchingResult;

  Color _getCategoryColor(String category) {
  switch (category) {
    case 'Great':
      return const Color(0xFF4CAF50);
    case 'Good':
      return const Color(0xFF8BC34A);
    case 'Moderate':
      return const Color(0xFFFFA726);
    case 'Poor':
      return const Color(0xFFFF6B35);
    case 'Very Poor':
      return const Color(0xFFFF4444);
    default:
      return const Color.fromARGB(255, 108, 106, 117);
  }

  
}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProduct();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ ADD THIS BLOCK:
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleReturnFromMarketplace();
    }
  }

  Future<void> _handleReturnFromMarketplace() async {
    if (!mounted) return;
    if (_didShowReturnModal) return;

    final pending = await _purchaseHistoryService.getPendingPurchase();
    if (pending == null) return;

    // Only show if it's the same product detail screen
    if (pending["productId"] != widget.productId) return;

    _didShowReturnModal = true;

    // Clear pending so it won't show again repeatedly
    await _purchaseHistoryService.clearPendingPurchase();

    if (!mounted) return;
    _showTrackPurchaseModal(marketplace: pending["marketplace"]);
  }


Future<void> _loadProduct() async {
  setState(() => _isLoading = true);
  try {
    // 1. Load product
    final product = await _service.getProductById(widget.productId);
    
    if (product == null) {
      setState(() => _isLoading = false);
      return;
    }

        // 2. Get user ID from secure storage (use same key as AuthService + fallback)
    final userId = await _storage.read(key: 'userId')
        ?? await _storage.read(key: 'user_id')
        ?? await _storage.read(key: 'id');

    print('🐛 [DETAIL] userId from secure storage: $userId');

    MatchingResult? matchingResult;
    
    if (userId != null && userId.isNotEmpty) {
      print('🔍 [DETAIL] Calculating matching score for user: $userId');
      
      try {
        // 3. Fetch user preferences
        final userPrefs = await _profileService.getUserPreferences(userId);
        
        // 4. Calculate matching score
        matchingResult = MatchingScoreService.calculateMatchingScore(
          userPrefs,
          product,
          product.rawApiData ?? {},
        );
        
        print('🎯 [DETAIL] Matching result: ${matchingResult.toString()}');
      } catch (e) {
        print('❌ [DETAIL] Error calculating match: $e');
      }
    } else {
      print('⚠ [DETAIL] No user ID found in secure storage - skipping matching score');
    }


    setState(() {
      _product = product;
      _matchingResult = matchingResult;
      _isLoading = false;
    });

    _loadAIAnalysis();

    // Add to history
    if (product != null) {
      await _history.addViewedProduct({
        "id": product.id,
        "name": product.name,
        "brand": product.brand,
        "imageUrl": product.imageUrl,
        "category": product.category,
      });
    }
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product: $e')),
      );
    }
  }
}

  void _showMarketplaceModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Purchase Through Your Local Marketplaces',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We will redirect you to one of these\nmarketplaces',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _openMarketplace('shopee');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Shopee',
                            style: TextStyle(
                              color: Color(0xFFEE4D2D),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _openMarketplace('tokopedia');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'tokopedia',
                            style: TextStyle(
                              color: Color(0xFF03AC0E),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToShoppingListModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add New Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                  'Are you sure you want to add this item on\nyour shopping list?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _shoppingListService.addItemFromOffProductId(widget.productId);

                          if (!mounted) return;
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/shopping-list');

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to shopping list ✅')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add item: $e')),
                          );
                        }

                        if (mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/shopping-list');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Add Item'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackPurchaseModal({String? marketplace}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Did you purchase this item?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (marketplace != null && marketplace.isNotEmpty)
              Text(
                'Marketplace: ${marketplace[0].toUpperCase()}${marketplace.substring(1)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            if (_product != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _product!.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _product!.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _getCategoryEmoji(_product!.category),
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getCategoryEmoji(_product!.category),
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Update your purchase record for better\nfuture suggestions.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _purchaseHistoryService.addPurchase(
                          productId: widget.productId,
                          marketplace: marketplace,
                        );

                        if (!mounted) return;
                        Navigator.of(context).pop(); // close modal

                        // go home and refresh sections
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase tracked ✅')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Track purchase'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // if pending existed, ensure cleared (safe)
                      await _purchaseHistoryService.clearPendingPurchase();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('I didn\'t buy it'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


      Future<void> _openMarketplace(String marketplace) async {
    if (_product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product data not loaded yet')),
      );
      return;
    }

    // Use the product name as the search keyword
    final keyword = Uri.encodeComponent(_product!.name.trim());
    late final Uri url;

    switch (marketplace) {
      case 'shopee':
        // ✅ Correct Shopee format
        url = Uri.parse('https://shopee.co.id/search?keyword=$keyword');
        break;
      case 'tokopedia':
        // ✅ Correct Tokopedia format: https://www.tokopedia.com/find/oreo
        url = Uri.parse('https://www.tokopedia.com/find/$keyword');
        break;
      default:
        return;
    }

    try {
      await _purchaseHistoryService.setPendingPurchase(
        productId: widget.productId,
        marketplace: marketplace,
      );
      _didShowReturnModal = false;
      
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open marketplace')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open marketplace: $e')),
      );
    }
  }Future<void> _loadAIAnalysis() async {
  if (_product == null) return;
  
  setState(() {
    _isLoadingAI = true;
    _aiError = null;
    _aiVerdict = '';
  });

  try {
    final userId = await _storage.read(key: 'userId')
        ?? await _storage.read(key: 'user_id');
    
    UserPreferences? userPrefs;
    if (userId != null && userId.isNotEmpty) {
      try {
        userPrefs = await _profileService.getUserPreferences(userId);
      } catch (e) {
        print('⚠️ [AI] Could not fetch user preferences: $e');
      }
    }

    final prompt = _buildAIPrompt(_product!, userPrefs);
    
    print('🤖 [AI] Sending prompt to Gemini via HTTP...');
    
    // ✅ USE DIRECT HTTP REQUEST INSTEAD
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyCUX7J7t5S127_HcyoHaiosNIZpzWAoLoo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      }),
    );

    print('🤖 [AI] Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final analysis = data['candidates'][0]['content']['parts'][0]['text'] ?? 
                      'Unable to generate analysis.';
      
      // ✅ PARSE THE VERDICT
      String verdict = '';
      final analysisUpper = analysis.toUpperCase();
      
      if (analysisUpper.startsWith('NOT RECOMMENDED')) {
        verdict = 'NOT RECOMMENDED';
      } else if (analysisUpper.startsWith('BUY WITH CAUTION')) {
        verdict = 'BUY WITH CAUTION';
      } else if (analysisUpper.startsWith('RECOMMENDED')) {
        verdict = 'RECOMMENDED';
      }
      
      if (mounted) {
        setState(() {
          _aiAnalysis = analysis;
          _aiVerdict = verdict;
          _isLoadingAI = false;
        });
        
        print('✅ [AI] Analysis generated: VERDICT = $verdict');
      }
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
    
  } catch (e) {
    print('❌ [AI] Full Error Details: $e');
    
    if (mounted) {
      setState(() {
        _aiError = 'Failed to generate AI analysis. Please try again.';
        _isLoadingAI = false;
      });
    }
  }
}

String _buildAIPrompt(Product product, UserPreferences? userPrefs) {
  final buffer = StringBuffer();
  
  buffer.writeln('You are a decisive Personal Shopping Companion AI assistant.');
  buffer.writeln('Your job is to give a CLEAR recommendation: RECOMMENDED, BUY WITH CAUTION, or NOT RECOMMENDED.');
  buffer.writeln();
  
  // PRODUCT INFORMATION
  buffer.writeln('=== PRODUCT INFORMATION ===');
  buffer.writeln('Name: ${product.name}');
  buffer.writeln('Brand: ${product.brand}');
  buffer.writeln('Category: ${product.category}');
  
  if (product.description.isNotEmpty) {
    buffer.writeln('Description: ${product.description}');
  }
  
  // Vegan/Vegetarian status
  if (product.isVegan) {
    buffer.writeln('✓ VEGAN PRODUCT');
  }
  
  // Ingredients
  if (product.ingredients.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('INGREDIENTS:');
    final allIngredients = product.ingredients.map((i) => i.name).join(', ');
    buffer.writeln(allIngredients);
  }
  
  // Nutrition
  if (product.calories > 0) {
    buffer.writeln();
    buffer.writeln('NUTRITION (per 100g):');
    buffer.writeln('- Calories: ${product.calories}');
    buffer.writeln('- Protein: ${product.protein}g');
    buffer.writeln('- Fat: ${product.fat}g');
  }
  
  // Nutrient Levels (CRITICAL for health conditions)
  if (product.rawApiData != null) {
    final nutrientLevels = product.rawApiData!['nutrient_levels'] as Map<String, dynamic>?;
    if (nutrientLevels != null && nutrientLevels.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('NUTRIENT LEVELS:');
      nutrientLevels.forEach((key, value) {
        buffer.writeln('- ${key}: ${value.toString().toUpperCase()}');
      });
    }
    
    final ecoScore = product.rawApiData!['ecoscore_grade']?.toString() ?? '';
    if (ecoScore.isNotEmpty && ecoScore != 'UNKNOWN') {
      buffer.writeln('- EcoScore: ${ecoScore.toUpperCase()}');
    }
  }
  
  // Scores
  if (product.nutritionScore.isNotEmpty && product.nutritionScore != 'UNKNOWN') {
    buffer.writeln('- NutriScore: ${product.nutritionScore}');
  }
  
  buffer.writeln();
  buffer.writeln('===================');
  buffer.writeln();
  
  // USER PROFILE - THIS IS CRITICAL!
  if (userPrefs != null && (userPrefs.hasPreferences || userPrefs.hasAvoidList || userPrefs.hasHealthConditions)) {
    buffer.writeln('=== USER PROFILE ===');
    
    // ALLERGENS & INGREDIENTS TO AVOID (HIGHEST PRIORITY!)
    if (userPrefs.avoidIngredients.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚠️ USER MUST AVOID THESE INGREDIENTS (ALLERGENS/SENSITIVITIES):');
      for (var ingredient in userPrefs.avoidIngredients) {
        buffer.writeln('- ${ingredient.toUpperCase()}');
      }
      buffer.writeln();
      buffer.writeln('CRITICAL INSTRUCTION: If the product name OR ingredients list contains ANY of these avoided ingredients, you MUST say "NOT RECOMMENDED" immediately. Be strict about this!');
      buffer.writeln();
    }
    
    // DIETARY PREFERENCES (SECOND PRIORITY)
    if (userPrefs.preferenceTags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('USER DIETARY PREFERENCES:');
      for (var tag in userPrefs.preferenceTags) {
        buffer.writeln('- $tag');
      }
      
      // Special handling for strict diets
      final strictVegan = userPrefs.preferenceTags.any((t) => 
        t.toLowerCase().contains('vegan'));
      final strictVegetarian = userPrefs.preferenceTags.any((t) => 
        t.toLowerCase().contains('vegetarian') && !t.toLowerCase().contains('vegan'));
      
      if (strictVegan) {
        buffer.writeln();
        buffer.writeln('⚠️ USER IS VEGAN: Product must contain NO animal products (meat, dairy, eggs, honey, etc.)');
        buffer.writeln('If this product contains ANY animal-derived ingredients, say "NOT RECOMMENDED".');
      } else if (strictVegetarian) {
        buffer.writeln();
        buffer.writeln('⚠️ USER IS VEGETARIAN: Product must contain NO meat, fish, or poultry.');
        buffer.writeln('If this product contains meat, fish, or poultry, say "NOT RECOMMENDED".');
      }
      buffer.writeln();
    }
    
    // HEALTH CONDITIONS (THIRD PRIORITY)
    if (userPrefs.healthConditions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('USER HEALTH CONDITIONS:');
      for (var condition in userPrefs.healthConditions) {
        buffer.writeln('- $condition');
      }
      buffer.writeln();
      buffer.writeln('Check nutrient levels against these conditions:');
      
      final conditionsLower = userPrefs.healthConditions.map((c) => c.toLowerCase()).toList();
      
      if (conditionsLower.any((c) => c.contains('diabet'))) {
        buffer.writeln('- Diabetes: Avoid HIGH sugar products');
      }
      if (conditionsLower.any((c) => c.contains('hypertension') || c.contains('blood pressure'))) {
        buffer.writeln('- Hypertension: Avoid HIGH salt/sodium products');
      }
      if (conditionsLower.any((c) => c.contains('cholesterol') || c.contains('heart'))) {
        buffer.writeln('- Heart/Cholesterol: Avoid HIGH saturated fat products');
      }
      if (conditionsLower.any((c) => c.contains('weight') || c.contains('obesity'))) {
        buffer.writeln('- Weight management: Prefer low calorie, low fat options');
      }
      buffer.writeln();
    }
    
    buffer.writeln('===================');
    buffer.writeln();
  }
  
  // TASK INSTRUCTIONS
  buffer.writeln('=== YOUR TASK ===');
  
  if (userPrefs != null && (userPrefs.hasPreferences || userPrefs.hasAvoidList || userPrefs.hasHealthConditions)) {
    buffer.writeln();
    buffer.writeln('Analyze this product for THIS SPECIFIC USER following these STRICT RULES:');
    buffer.writeln();
    buffer.writeln('DECISION RULES (CHECK IN THIS ORDER):');
    buffer.writeln();
    buffer.writeln('1. ALLERGENS/AVOIDED INGREDIENTS (IMMEDIATE REJECTION):');
    buffer.writeln('   - Check product name AND ingredients list');
    buffer.writeln('   - If ANY avoided ingredient is present → Say "NOT RECOMMENDED" immediately');
    buffer.writeln('   - Example: User avoids "nuts", product is "Peanut Butter" → NOT RECOMMENDED');
    buffer.writeln('   - Example: User avoids "soy", ingredients contain "soy lecithin" → NOT RECOMMENDED');
    buffer.writeln();
    buffer.writeln('2. DIETARY RESTRICTIONS (STRICT ENFORCEMENT):');
    buffer.writeln('   - If user is VEGAN and product contains ANY animal products → NOT RECOMMENDED');
    buffer.writeln('   - If user is VEGETARIAN and product contains meat/fish → NOT RECOMMENDED');
    buffer.writeln('   - Be strict! Even small amounts count.');
    buffer.writeln();
    buffer.writeln('3. HEALTH CONDITIONS (CRITICAL CONCERNS):');
    buffer.writeln('   - Check nutrient levels against health conditions');
    buffer.writeln('   - If product has HIGH levels of nutrients user should avoid → BUY WITH CAUTION or NOT RECOMMENDED');
    buffer.writeln('   - Example: Diabetic user + HIGH sugar product → BUY WITH CAUTION or NOT RECOMMENDED');
    buffer.writeln();
    buffer.writeln('4. GENERAL FIT (IF NO CRITICAL ISSUES):');
    buffer.writeln('   - If product passes all above checks → RECOMMENDED or BUY WITH CAUTION');
    buffer.writeln('   - Consider nutritional quality and user preferences');
    buffer.writeln();
    buffer.writeln('OUTPUT FORMAT:');
    buffer.writeln('Give a clear verdict in 3-5 sentences:');
    buffer.writeln('- Start with: "RECOMMENDED", "BUY WITH CAUTION", or "NOT RECOMMENDED"');
    buffer.writeln('- Explain WHY clearly and directly');
    buffer.writeln('- Mention specific ingredients or nutrients of concern if any');
    buffer.writeln('- Be honest and protective of the user\'s health');
    buffer.writeln();
    buffer.writeln('Example outputs:');
    buffer.writeln('- "NOT RECOMMENDED. This product contains peanuts, which you must avoid due to your nut allergy. Even trace amounts can be dangerous."');
    buffer.writeln('- "NOT RECOMMENDED. This product contains chicken, which conflicts with your vegan diet preference."');
    buffer.writeln('- "BUY WITH CAUTION. This product has high sugar content (marked as HIGH), which may not be ideal for your diabetes management. Consider consuming in moderation."');
    buffer.writeln('- "RECOMMENDED. This product aligns well with your dietary preferences and contains no ingredients you need to avoid. The nutritional profile is good."');
  } else {
    buffer.writeln();
    buffer.writeln('No user preferences available. Provide a GENERAL health analysis:');
    buffer.writeln();
    buffer.writeln('1. Assess nutritional quality (NutriScore, nutrient levels)');
    buffer.writeln('2. Identify any concerning ingredients (additives, high sugar/salt/fat)');
    buffer.writeln('3. Suggest who would benefit from this product');
    buffer.writeln('4. Note any general health concerns');
    buffer.writeln();
    buffer.writeln('Give your analysis in 3-5 clear sentences. Be informative and helpful.');
  }
  
  return buffer.toString();
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ========= PRODUCT IMAGE =========
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: _product!.imageUrl.isNotEmpty
                      ? Image.network(_product!.imageUrl, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(_getCategoryEmoji(_product!.category),
                                    style: const TextStyle(fontSize: 60))),
                          );
                        })
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text(_getCategoryEmoji(_product!.category),
                                  style: const TextStyle(fontSize: 60)))),
                ),
              ),
            ),

            // ========= PRODUCT NAME & BRAND =========
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  Text(_product!.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(_product!.brand,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),

            // ========= BADGES =========
            if (_product!.isVegan || _product!.isEcoFriendly)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_product!.isVegan)
                      _buildBadge('Vegan', Icons.eco, const Color(0xFF4CAF50)),
                    if (_product!.isEcoFriendly)
                      _buildBadge('Eco-friendly', Icons.water_drop, 
                          const Color(0xFF2196F3)),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // // ========= MATCH PERCENTAGE =========
            // if (_matchingResult != null && !_matchingResult!.showScoreOnly)
            //   _buildCard(
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             RichText(
            //               text: TextSpan(
            //                 style: const TextStyle(fontSize: 15),
            //                 children: [
            //                   TextSpan(
            //                     text: '${_matchingResult!.totalScore.toStringAsFixed(0)}% ',
            //                     style: const TextStyle(
            //                         fontWeight: FontWeight.bold, color: Colors.black),
            //                   ),
            //                   const TextSpan(
            //                       text: 'AI Match Score',
            //                       style: TextStyle(color: Colors.black)),
            //                 ],
            //               ),
            //             ),
            //             Container(
            //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            //               decoration: BoxDecoration(
            //                   color: _getCategoryColor(_matchingResult!.category),
            //                   borderRadius: BorderRadius.circular(14)),
            //               child: Text(_matchingResult!.category,
            //                   style: const TextStyle(
            //                       fontSize: 11,
            //                       color: Colors.white,
            //                       fontWeight: FontWeight.w600)),
            //             ),
            //           ],
            //         ),
            //         if (_matchingResult!.confidenceLabel != null) ...[
            //           const SizedBox(height: 8),
            //           Text(
            //             _matchingResult!.confidenceLabel!,
            //             style: const TextStyle(fontSize: 11, color: Colors.orange),
            //           ),
            //         ],
            //         if (_matchingResult!.breakdown.isNotEmpty) ...[
            //           const SizedBox(height: 12),
            //           const Text('Score Breakdown',
            //               style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            //           const SizedBox(height: 8),
            //           ..._matchingResult!.breakdown.entries.map((entry) => Padding(
            //                 padding: const EdgeInsets.only(bottom: 6.0),
            //                 child: Row(
            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                   children: [
            //                     Text(entry.key,
            //                         style:
            //                             const TextStyle(fontSize: 12, color: Colors.grey)),
            //                     Text('${entry.value.toStringAsFixed(0)}%',
            //                         style: const TextStyle(
            //                             fontSize: 12, fontWeight: FontWeight.w600)),
            //                   ],
            //                 ),
            //               )),
            //         ],
            //       ],
            //     ),
            //   ),

            // ========= AI ANALYSIS (SMART VERSION) =========
_buildCard(
  title: 'AI Personal Analysis',
  icon: Icons.auto_awesome,
  iconColor: const Color(0xFF6B4CE6),
  child: _isLoadingAI
      ? const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4CE6)),
                ),
                SizedBox(height: 12),
                Text(
                  'Analyzing product for you...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        )
      : _aiError != null
          ? Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(
                  _aiError!,
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loadAIAnalysis,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Analysis'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B4CE6),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VERDICT BADGE (BIG & CLEAR)
                if (_aiVerdict.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getVerdictColor(_aiVerdict).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getVerdictColor(_aiVerdict),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getVerdictIcon(_aiVerdict),
                          color: _getVerdictColor(_aiVerdict),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _aiVerdict,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getVerdictColor(_aiVerdict),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // AI EXPLANATION
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.psychology, 
                          color: Color(0xFF6B4CE6), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _aiAnalysis.isEmpty 
                              ? 'Generating personalized analysis...' 
                              : _aiAnalysis,
                          style: const TextStyle(
                            fontSize: 13, 
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // SHOW MATCH SCORE ONLY IF NOT "NOT RECOMMENDED"
                if (_matchingResult != null && 
                    !_matchingResult!.showScoreOnly && 
                    _aiVerdict != 'NOT RECOMMENDED') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Match Score Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Match Score',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_matchingResult!.totalScore.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(_matchingResult!.category),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(_matchingResult!.category),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _matchingResult!.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        if (_matchingResult!.breakdown.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          ..._matchingResult!.breakdown.entries.map((entry) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // WARNING IF "NOT RECOMMENDED"
                if (_aiVerdict == 'NOT RECOMMENDED') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF4444),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, 
                            color: Color(0xFFFF4444), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This product does not match your dietary preferences or health conditions. Match scoring has been skipped.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF4444),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
),

            // ========= IDEAL FOR & NUTRITION (SIDE BY SIDE) =========
            _buildCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IDEAL FOR
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ideal For',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        _product!.idealFor.isNotEmpty
                            ? Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: _product!.idealFor
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFF3E8FF),
                                              borderRadius: BorderRadius.circular(14)),
                                          child: Text(tag,
                                              style: const TextStyle(
                                                  fontSize: 10, color: Color(0xFF6B4CE6))),
                                        ))
                                    .toList(),
                              )
                            : const Text('No information',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // NUTRITION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nutrition',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Color(0xFFFF6B35), size: 16),
                            const SizedBox(width: 4),
                            Text('${_product!.calories}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            const Text('Calories',
                                style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_product!.protein.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                                const Text('Protein',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_product!.fat.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                                const Text('Fat',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ========= ETHICS SCORE =========
            _buildCard(
              title: 'Ethics Score',
              trailing: Text('${_product!.ethicsScore}/100',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              child: _product!.ethicsScore > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('AI Calculation',
                                style: TextStyle(fontSize: 11, color: Color(0xFF6B4CE6))),
                            SizedBox(width: 4),
                            Icon(Icons.auto_awesome, size: 11, color: Color(0xFF6B4CE6)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _product!.ethicsScore / 100,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _getEthicsColor(_product!.ethicsScore)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEthicsRow('Environmental Impact', _product!.environmentalImpact),
                        const SizedBox(height: 8),
                        _buildEthicsRow('Animal Welfare', _product!.animalWelfare),
                        const SizedBox(height: 8),
                        _buildEthicsRow('Fair Labor', _product!.fairLabor),
                      ],
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= INGREDIENTS (NOT SCROLLABLE, HIDDEN OVERFLOW) =========
            _buildCard(
              title: 'Ingredients Breakdown',
              child: _product!.ingredients.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _product!.ingredients
                              .take(6)
                              .map((ing) => _buildIngredientChip(ing.name, ing.status))
                              .toList(),
                        ),
                        if (_product!.ingredients.length > 6)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // TODO: Show full ingredients modal
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B4CE6),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= POSITIVES =========
            _buildCard(
              title: 'Positives',
              child: _product!.positives.isNotEmpty
                  ? Column(
                      children: _product!.positives
                          .map((positive) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildNutrientRow(
                                  positive.name,
                                  positive.value,
                                  positive.details,
                                  isPositive: true,
                                ),
                              ))
                          .toList(),
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= NEGATIVES =========
            _buildCard(
              title: 'Negatives',
              child: _product!.negatives.isNotEmpty
                  ? Column(
                      children: _product!.negatives
                          .map((negative) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildNutrientRow(
                                  negative.name,
                                  negative.value,
                                  negative.details,
                                  isPositive: false,
                                ),
                              ))
                          .toList(),
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= CERTIFICATIONS =========
            _buildCard(
              title: 'Certifications',
              child: _product!.certifications.isNotEmpty
                  ? Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _product!.certifications
                          .take(6)
                          .map((cert) => _buildCertBadge(_getCertificationEmoji(cert)))
                          .toList(),
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomSheet: _buildBottomButtons(),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddToShoppingListModal,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: const Text('Add to Shop List', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showTrackPurchaseModal,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Record Purchase', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showMarketplaceModal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Purchase Online',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    String? title,
    Widget? trailing,
    IconData? icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      if (icon != null) ...[
                        const SizedBox(width: 4),
                        Icon(icon, size: 14, color: iconColor),
                      ],
                    ],
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildEthicsRow(String label, String value) {
    Color dotColor = Colors.grey;
    if (value.toLowerCase().contains('low') ||
        value.toLowerCase().contains('excellent') ||
        value.toLowerCase().contains('certified')) {
      dotColor = const Color(0xFF4CAF50);
    } else if (value.toLowerCase().contains('moderate') ||
        value.toLowerCase().contains('good')) {
      dotColor = const Color(0xFFFFA726);
    } else if (value.toLowerCase().contains('high') ||
        value.toLowerCase().contains('contains')) {
      dotColor = const Color(0xFFFF4444);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Row(
          children: [
            Icon(Icons.circle, color: dotColor, size: 6),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientRow(String name, String value, List<String>? details,
      {required bool isPositive}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.warning,
              color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
            Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        if (details != null && details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details
                  .map((detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text('• $detail',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildIngredientChip(String name, String status) {
    Color color, bgColor;
    IconData? icon;
    switch (status.toLowerCase()) {
      case 'reduced':
        color = const Color(0xFFFF4444);
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.flag;
        break;
      case 'monitored':
        color = const Color(0xFFFFA726);
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.warning_amber;
        break;
      default:
        color = Colors.grey;
        bgColor = const Color(0xFFF5F5F5);
        icon = null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              name,
              style: TextStyle(fontSize: 10, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertBadge(String emoji) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
    );
  }

  Color _getEthicsColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFFF4444);
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'sweets':
        return '🍫';
      case 'beverages':
        return '🥤';
      case 'dairy':
        return '🧀';
      case 'supplements':
        return '💊';
      default:
        return '📦';
    }
  }

  String _getCertificationEmoji(String cert) {
    if (cert.contains('nutriscore')) return '📊';
    if (cert.contains('ecoscore')) return '🌍';
    if (cert.contains('organic')) return '🌿';
    if (cert.contains('vegan')) return '🌱';
    if (cert.contains('fair-trade')) return '⚖';
    if (cert.contains('gluten-free')) return '🌾';
    if (cert.contains('palm-oil-free')) return '🌴';
    return '✓';
  }

  /// Build comprehensive score explanation from breakdown
List<Widget> _buildScoreExplanation() {
  if (_matchingResult == null || _matchingResult!.breakdown.isEmpty) {
    return [
      const Text(
        'No scoring factors available.',
        style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
      ),
    ];
  }

  final widgets = <Widget>[];
  
  // Map factor names to user-friendly descriptions
  final factorDescriptions = {
    'Personal Fit': _getPersonalFitDescription(),
    'Ingredient Compatibility': _getIngredientCompatibilityDescription(),
    'Health Safety': _getHealthSafetyDescription(),
    'Ethical Values': _getEthicalValuesDescription(),
    'Product Quality': _getProductQualityDescription(),
  };

  // Build explanation for each factor
  _matchingResult!.breakdown.forEach((factor, score) {
    final description = factorDescriptions[factor] ?? 'No description available';
    
    widgets.add(
      _buildFactorExplanation(
        factor: factor,
        score: score,
        description: description,
      ),
    );
    
    widgets.add(const SizedBox(height: 10));
  });

  return widgets;
}

/// Build individual factor explanation
Widget _buildFactorExplanation({
  required String factor,
  required double score,
  required String description,
}) {
  Color scoreColor;
  if (score >= 75) {
    scoreColor = const Color(0xFF4CAF50);
  } else if (score >= 50) {
    scoreColor = const Color(0xFFFFA726);
  } else {
    scoreColor = const Color(0xFFFF4444);
  }

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                factor,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

/// Get Personal Fit description
String _getPersonalFitDescription() {
  final userPrefs = _matchingResult?.breakdown['Personal Fit'] ?? 0;
  
  if (userPrefs >= 80) {
    return 'This product strongly aligns with your dietary preferences and lifestyle choices. Most of your selected tags match this product.';
  } else if (userPrefs >= 50) {
    return 'This product partially matches your preferences. Some of your dietary choices align with this product\'s characteristics.';
  } else {
    return 'This product doesn\'t strongly match your stated preferences. Consider reviewing if this fits your dietary goals.';
  }
}

/// Get Ingredient Compatibility description
String _getIngredientCompatibilityDescription() {
  final icScore = _matchingResult?.breakdown['Ingredient Compatibility'] ?? 100;
  
  if (icScore == 100) {
    return 'Great news! This product contains none of the ingredients you\'re avoiding.';
  } else if (icScore >= 75) {
    return 'This product contains minimal ingredients from your avoid list. Review the ingredients section for details.';
  } else if (icScore >= 50) {
    return 'This product contains some ingredients you prefer to avoid. Check the ingredients breakdown carefully.';
  } else {
    return 'Warning: This product contains multiple ingredients from your avoid list. Not recommended based on your preferences.';
  }
}

/// Get Health Safety description
String _getHealthSafetyDescription() {
  final hsScore = _matchingResult?.breakdown['Health Safety'] ?? 100;
  
  if (hsScore == 100) {
    return 'This product is safe for your health conditions. No nutritional concerns detected based on your profile.';
  } else if (hsScore >= 75) {
    return 'Generally safe, but contains moderate levels of nutrients you should monitor based on your health conditions.';
  } else if (hsScore >= 50) {
    return 'This product has some nutritional aspects that don\'t align well with your health conditions. Consume with caution.';
  } else {
    return 'This product contains high levels of nutrients you should avoid based on your health conditions. Not recommended.';
  }
}

/// Get Ethical Values description
String _getEthicalValuesDescription() {
  final evScore = _matchingResult?.breakdown['Ethical Values'] ?? 0;
  
  if (evScore >= 80) {
    return 'Excellent environmental rating (EcoScore A-B). This product has minimal ecological impact.';
  } else if (evScore >= 60) {
    return 'Moderate environmental impact (EcoScore C). Acceptable but room for improvement.';
  } else if (evScore >= 40) {
    return 'High environmental impact (EcoScore D). Consider more eco-friendly alternatives.';
  } else {
    return 'Very high environmental impact (EcoScore E). This product significantly impacts the environment.';
  }
}

/// Get Product Quality description
String _getProductQualityDescription() {
  final pqScore = _matchingResult?.breakdown['Product Quality'] ?? 0;
  
  final nutriScore = _product?.nutritionScore ?? '';
  final certCount = _product?.certifications.length ?? 0;
  
  String desc = '';
  
  if (nutriScore.isNotEmpty && nutriScore != 'UNKNOWN') {
    desc += 'NutriScore: $nutriScore. ';
  }
  
  if (certCount > 0) {
    desc += '$certCount certification(s) found. ';
  }
  
  if (pqScore >= 80) {
    desc += 'Excellent nutritional quality with strong certifications.';
  } else if (pqScore >= 60) {
    desc += 'Good quality product with acceptable nutritional profile.';
  } else if (pqScore >= 40) {
    desc += 'Average quality. Consider healthier alternatives.';
  } else {
    desc += 'Below average nutritional quality.';
  }
  
  return desc.trim();
}

/// Show full analysis modal
void _showFullAnalysisModal() {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6B4CE6)),
                const SizedBox(width: 8),
                const Text(
                  'Full AI Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.construction, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'LLM Integration Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Advanced AI-powered product analysis with detailed recommendations will be available soon.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (_matchingResult != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Current Score Breakdown:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._matchingResult!.breakdown.entries.map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${entry.value.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
