// lib/services/search_history_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchHistoryService {
  static const String _key = 'search_history';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get saved history as a list of strings (most recent first)
  Future<List<String>> getHistory() async {
    final jsonString = await _storage.read(key: _key);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add a new query to history.
  /// - Removes duplicates
  /// - Inserts at the top
  /// - Trims to max 20 items
  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final history = await getHistory();

    // remove same query (case-insensitive)
    history.removeWhere(
      (q) => q.toLowerCase() == trimmed.toLowerCase(),
    );

    // insert at top
    history.insert(0, trimmed);

    // keep only last 20
    const maxLength = 20;
    if (history.length > maxLength) {
      history.removeRange(maxLength, history.length);
    }

    await _storage.write(key: _key, value: jsonEncode(history));
  }

  /// Optional: clear history if you ever need it
  Future<void> clearHistory() async {
    await _storage.delete(key: _key);
  }
}
