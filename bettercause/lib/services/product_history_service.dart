// lib/services/product_history_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductHistoryService {
  static const _userIdKey = 'userId';
  static const _prefix = 'viewed_products_';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<String> _requireUserId() async {
    final userId = await _secure.read(key: _userIdKey);
    if (userId == null || userId.isEmpty) {
      throw Exception('userId not found. Make sure AuthProvider.login() stored it.');
    }
    return userId;
  }

  Future<String> _key() async {
    final userId = await _requireUserId();
    return '$_prefix$userId';
  }

  /// Save viewed product (most recent first, dedupe by id, max 10)
  Future<void> addViewedProduct(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();

    final id = product["id"]?.toString();
    if (id == null || id.isEmpty) return;

    List<String> existing = prefs.getStringList(key) ?? [];

    existing.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded["id"]?.toString() == id;
    });

    existing.insert(0, jsonEncode(product));

    if (existing.length > 10) {
      existing = existing.sublist(0, 10);
    }

    await prefs.setStringList(key, existing);
  }

  Future<List<Map<String, dynamic>>> getViewedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();

    final list = prefs.getStringList(key) ?? [];
    return list.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item));
    }).toList();
  }

  Future<void> removeProduct(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();

    List<String> existing = prefs.getStringList(key) ?? [];

    existing.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded["id"]?.toString() == id;
    });

    await prefs.setStringList(key, existing);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    await prefs.remove(key);
  }
}
