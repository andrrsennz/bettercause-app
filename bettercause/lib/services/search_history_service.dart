// lib/services/search_history_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchHistoryService {
  static const _userIdKey = 'userId';
  static const _prefix = 'search_history_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> _requireUserId() async {
    final userId = await _storage.read(key: _userIdKey);
    if (userId == null || userId.isEmpty) {
      throw Exception('userId not found. Make sure AuthProvider.login() stored it.');
    }
    return userId;
  }

  Future<String> _historyKey() async {
    final userId = await _requireUserId();
    return '$_prefix$userId';
  }

  /// Get saved history (most recent first)
  Future<List<String>> getHistory({int limit = 20}) async {
    final key = await _historyKey();
    final jsonString = await _storage.read(key: key);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];
      final list = decoded.map((e) => e.toString()).toList();
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add query (dedupe, insert top, max limit)
  Future<void> addQuery(String query, {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final key = await _historyKey();
    final history = await getHistory(limit: 9999);

    // remove same query (case-insensitive)
    history.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());

    // insert at top
    history.insert(0, trimmed);

    // clamp
    if (history.length > limit) {
      history.removeRange(limit, history.length);
    }

    await _storage.write(key: key, value: jsonEncode(history));
  }

  Future<void> removeQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final key = await _historyKey();
    final history = await getHistory(limit: 9999);

    history.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    await _storage.write(key: key, value: jsonEncode(history));
  }

  Future<void> clearHistory() async {
    final key = await _historyKey();
    await _storage.delete(key: key);
  }
}
