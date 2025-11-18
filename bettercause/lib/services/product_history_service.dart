import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductHistoryService {
  static const String _key = "viewed_products";

  /// Simpan product yang sudah dilihat
  Future<void> addViewedProduct(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> existing = prefs.getStringList(_key) ?? [];

    // hapus dulu kalau sudah ada id yang sama
    existing.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded["id"] == product["id"];
    });

    // masukkan yang baru di paling atas
    existing.insert(0, jsonEncode(product));

    // batasi maksimal 10 item
    if (existing.length > 10) {
      existing = existing.sublist(0, 10);
    }

    await prefs.setStringList(_key, existing);
  }

  /// Ambil semua produk yang pernah dilihat
  Future<List<Map<String, dynamic>>> getViewedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    return list.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item));
    }).toList();
  }

  /// Hapus satu produk berdasarkan id
  Future<void> removeProduct(String id) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> existing = prefs.getStringList(_key) ?? [];

    existing.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded["id"] == id;
    });

    await prefs.setStringList(_key, existing);
  }

  /// Hapus semua history
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
