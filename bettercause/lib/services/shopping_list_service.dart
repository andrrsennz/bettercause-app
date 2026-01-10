// lib/services/shopping_list_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_item_model.dart';
import '../models/search_model.dart';
import '../services/search_service.dart';

class ShoppingListService {
  final _secure = const FlutterSecureStorage();
  final SearchService _searchService = SearchService();

  /// Each user gets their own shopping list storage key:
  /// shopping_list_<userId> , fallback: shopping_list_guest
  Future<String> _storageKey() async {
    final userId = await _secure.read(key: 'userId') ??
        await _secure.read(key: 'user_id') ??
        await _secure.read(key: 'id');

    final uid = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim()
        : 'guest';

    return 'shopping_list_$uid';
  }

  Future<List<ShoppingItem>> getShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _storageKey();

    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final items = decoded
        .whereType<Map>()
        .map((m) => ShoppingItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // newest first
    items.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return items;
  }

  Future<void> _saveAll(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _storageKey();

    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(key, raw);
  }

  Future<void> addItem(ShoppingItem item) async {
    final items = await getShoppingList();

    // prevent duplicates by id
    final exists = items.any((x) => x.id == item.id);
    if (exists) return;

    items.add(item);
    await _saveAll(items);
  }

  Future<void> deleteItem(String itemId) async {
    final items = await getShoppingList();
    items.removeWhere((x) => x.id == itemId);
    await _saveAll(items);
  }

  Future<void> toggleItemStatus(String itemId) async {
    final items = await getShoppingList();

    final idx = items.indexWhere((x) => x.id == itemId);
    if (idx == -1) return;

    final updated = items[idx].copyWith(isBought: !items[idx].isBought);
    items[idx] = updated;

    await _saveAll(items);
  }

  /// ✅ REAL: add to shopping list using OpenFoodFacts productId (barcode)
  Future<void> addItemFromOffProductId(String productId) async {
    final Product? product = await _searchService.getProductById(productId);
    if (product == null) {
      throw Exception('OpenFoodFacts product not found for id: $productId');
    }

    final item = ShoppingItem(
      id: product.id, // IMPORTANT: keep OFF id for ProductDetail navigation
      name: product.name.trim().isEmpty ? "Unknown product" : product.name,
      brand: product.brand.trim().isEmpty ? "-" : product.brand,
      imageUrl: product.imageUrl,
      category: _mapToShoppingCategory(product.category),
      isBought: false,
      addedDate: DateTime.now(),
    );

    await addItem(item);
  }

  /// Optional: manual add
  Future<void> addManualItem({
    required String name,
    required String brand,
    required String category,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final item = ShoppingItem(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      brand: brand.trim().isEmpty ? '-' : brand.trim(),
      imageUrl: '',
      category: category,
      isBought: false,
      addedDate: DateTime.now(),
    );

    await addItem(item);
  }

  String _mapToShoppingCategory(String offCategory) {
    final c = offCategory.toLowerCase();

    // Your OFF app categories are sweets/beverages/dairy/supplements mostly
    // We'll map them to Food & Beverages
    if (c.contains('beauty')) return 'Beauty & Care';
    if (c.contains('house')) return 'Household';
    if (c.contains('electronic')) return 'Electronics';

    return 'Food & Beverages';
  }
}
