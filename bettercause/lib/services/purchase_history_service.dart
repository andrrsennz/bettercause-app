// lib/services/purchase_history_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_record_model.dart';

class PurchaseHistoryService {
  final _secure = const FlutterSecureStorage();

  Future<String> _userId() async {
    final userId = await _secure.read(key: 'userId') ??
        await _secure.read(key: 'user_id') ??
        await _secure.read(key: 'id');
    return (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
  }

  Future<String> _purchaseKey() async => 'purchases_${await _userId()}';
  Future<String> _pendingKey() async => 'pending_purchase_${await _userId()}';
  Future<String> _ratingKey() async => 'purchase_ratings_${await _userId()}';

  // -------------------------
  // Purchases list
  // -------------------------
  Future<List<PurchaseRecord>> getPurchases({int? limit}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _purchaseKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final list = decoded
        .whereType<Map>()
        .map((m) => PurchaseRecord.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // newest first
    list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

    if (limit != null && limit > 0 && list.length > limit) {
      return list.take(limit).toList();
    }
    return list;
  }

  Future<void> _savePurchases(List<PurchaseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _purchaseKey();
    final raw = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(key, raw);
  }

  /// Add a purchase record (dedupe by productId: newest wins)
  Future<void> addPurchase({
    required String productId,
    String? marketplace,
  }) async {
    final records = await getPurchases();
    records.removeWhere((r) => r.productId == productId);

    records.add(
      PurchaseRecord(
        productId: productId,
        purchasedAt: DateTime.now(),
        marketplace: marketplace,
        experience: await getExperience(productId), // if already rated
      ),
    );

    await _savePurchases(records);
  }

  // -------------------------
  // Pending purchase (for "Purchase Online" return flow)
  // -------------------------
  Future<void> setPendingPurchase({
    required String productId,
    required String marketplace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _pendingKey();
    await prefs.setString(
      key,
      jsonEncode({
        "productId": productId,
        "marketplace": marketplace,
        "createdAt": DateTime.now().toIso8601String(),
      }),
    );
  }

  /// returns null if no pending
  Future<Map<String, String>?> getPendingPurchase() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _pendingKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;

    final productId = (decoded["productId"] ?? "").toString();
    final marketplace = (decoded["marketplace"] ?? "").toString();
    if (productId.isEmpty) return null;

    return {
      "productId": productId,
      "marketplace": marketplace,
    };
  }

  Future<void> clearPendingPurchase() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _pendingKey();
    await prefs.remove(key);
  }

  // -------------------------
  // Experience / rating
  // GREAT / AVERAGE / BAD
  // -------------------------
  Future<Map<String, String>> getAllExperiences() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _ratingKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};

    return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  Future<String?> getExperience(String productId) async {
    final all = await getAllExperiences();
    return all[productId];
  }

  Future<void> setExperience({
    required String productId,
    required String experience, // GREAT / AVERAGE / BAD
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _ratingKey();

    final all = await getAllExperiences();
    all[productId] = experience;

    await prefs.setString(key, jsonEncode(all));

    // ALSO update existing purchase record if exists
    final records = await getPurchases();
    final idx = records.indexWhere((r) => r.productId == productId);
    if (idx != -1) {
      records[idx] = records[idx].copyWith(experience: experience);
      await _savePurchases(records);
    }
  }

  // -------------------------
  // Items to rate: purchases that do not have experience
  // -------------------------
  Future<List<String>> getItemsToRateProductIds({int limit = 10}) async {
    final purchases = await getPurchases();
    final ids = <String>[];

    for (final p in purchases) {
      if (p.experience == null || p.experience!.isEmpty) {
        ids.add(p.productId);
      }
      if (ids.length >= limit) break;
    }
    return ids;
  }
}
