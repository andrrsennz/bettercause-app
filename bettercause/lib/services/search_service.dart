// lib/services/search_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/search_model.dart';

class SearchService {
  // Open Food Facts base URL
  static const String _offBaseUrl = 'https://world.openfoodfacts.org';

  // ========= BROWSE MODE (dummy for now) =========

  Future<List<Product>> getProducts() async {
    // You can keep this dummy list for browse mode.
    await Future.delayed(const Duration(seconds: 1));

    return [
      Product(
        id: '1',
        name: 'Oatly Oat Milk, Original',
        brand: 'Oatly',
        imageUrl: '',
        category: 'beverages',
        nutritionScore: 'B',
        price: 3.99,
        addedDate: DateTime.now().subtract(const Duration(days: 1)),
        isVegan: true,
        isEcoFriendly: true,
        matchPercentage: 92,
        description:
            'Oatly Oat Drink is a well-formulated plant-based milk alternative with a good fortification and low saturated fat. It also has lower protein content than soy milk, so it may not be ideal for consumers looking for a dairy alternative with high protein.',
        idealFor: ['Lactose Intolerant', 'Vegan', 'Vegetarian'],
        calories: 59,
        protein: 1.0,
        fat: 3.0,
        ethicsScore: 70,
        environmentalImpact: 'Moderate',
        animalWelfare: 'N/A',
        fairLabor: 'N/A',
        ingredients: [
          ProductIngredient(
              name: 'Rapeseed Oil', status: 'reduced', subIngredients: []),
          ProductIngredient(name: 'Monitored', status: 'monitored', subIngredients: [
            'Oats',
            'Water',
            'Sea salt'
          ]),
        ],
        positives: [
          ProductNutrient(name: 'Sodium', icon: '🧂', value: '0.1g', hasInfo: true),
          ProductNutrient(name: 'Sugar', icon: '🍬', value: '3.5g', hasInfo: true),
          ProductNutrient(
            name: 'Vitamins',
            icon: '💊',
            value: '3',
            hasInfo: true,
            details: ['B2', 'D2', 'Riboflavin'],
          ),
        ],
        negatives: [
          ProductNutrient(
            name: 'Additives',
            icon: '⚠️',
            value: '1',
            hasInfo: true,
            details: ['Dipotassium Phosphate'],
          ),
        ],
        certifications: ['nutriscore-b', 'green-score', 'organic', 'leaf'],
        alternatives: const [],
      ),
      // ... (you can keep the rest of your dummy items here unchanged)
    ];
  }

  // ========= REAL SEARCH AGAINST OPEN FOOD FACTS =========

  /// Search products in Open Food Facts.
  ///
  /// Uses `search_terms` query and maps the OFF products into our Product model.
  Future<List<Product>> searchProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final uri = Uri.parse('$_offBaseUrl/cgi/search.pl').replace(
      queryParameters: <String, String>{
        'search_terms': trimmed,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '20',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to search products (status ${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    final List<dynamic> rawProducts =
        data['products'] as List<dynamic>? ?? <dynamic>[];

    final products = rawProducts
        .map((p) => Product.fromOpenFoodFacts(p as Map<String, dynamic>))
        .where((product) => product.name.trim().isNotEmpty)
        .toList();

    return products;
  }

  /// Fetch a single product by OFF barcode / ID.
  ///
  /// Uses `https://world.openfoodfacts.org/api/v0/product/{code}.json`
  Future<Product?> getProductById(String productId) async {
    if (productId.trim().isEmpty) return null;

    final uri = Uri.parse('$_offBaseUrl/api/v0/product/$productId.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load product (status ${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    // OFF uses "status":1 when product exists
    if (data['status'] != 1) {
      return null;
    }

    final productJson = data['product'] as Map<String, dynamic>;
    return Product.fromOpenFoodFacts(productJson);
  }

  // ========= OTHER ACTIONS (still dummy / app-backend later) =========

  Future<List<Product>> getProductsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final allProducts = await getProducts();
    return allProducts.where((p) => p.category == category).toList();
  }

  Future<void> addToShoppingList(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['sweets', 'beverages', 'dairy', 'supplements'];
  }
}
