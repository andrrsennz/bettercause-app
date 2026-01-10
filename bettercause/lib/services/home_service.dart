// lib/services/home_service.dart

import '../models/product_model.dart';
import '../services/search_service.dart';
import '../services/purchase_history_service.dart';

class HomeService {
  final SearchService _searchService = SearchService();
  final PurchaseHistoryService _purchaseHistory = PurchaseHistoryService();

  /// Get all home screen data:
  /// - itemsToRate: products in purchase history that don't have experience yet (max 10)
  /// - latestPurchases: latest purchases (max 5)
  /// - latestScans: empty for now (implement later if you have scan storage)
  Future<Map<String, List<Product>>> getHomeData() async {
    // Optional tiny delay to make UI feel smooth (can remove)
    // await Future.delayed(const Duration(milliseconds: 200));

    // -------------------------
    // 1) LATEST PURCHASES (max 5)
    // -------------------------
    final purchaseRecords = await _purchaseHistory.getPurchases(limit: 5);

    final List<Product> latestPurchases = [];
    for (final record in purchaseRecords) {
      final p = await _searchService.getProductById(record.productId);
      if (p != null) {
        // Your Product model supports purchaseDate, so we fill it here
        latestPurchases.add(
          Product(
            id: p.id,
            name: p.name,
            brand: p.brand,
            imageUrl: p.imageUrl,
            purchaseDate: record.purchasedAt,
            scanDate: null,
          ),
        );
      }
    }

    // -------------------------
    // 2) ITEMS TO RATE (max 10)
    // purchases that don't have experience yet
    // -------------------------
    final toRateIds = await _purchaseHistory.getItemsToRateProductIds(limit: 10);

    final List<Product> itemsToRate = [];
    for (final id in toRateIds) {
      final p = await _searchService.getProductById(id);
      if (p != null) {
        itemsToRate.add(
          Product(
            id: p.id,
            name: p.name,
            brand: p.brand,
            imageUrl: p.imageUrl,
            purchaseDate: null,
            scanDate: null,
          ),
        );
      }
    }

    // -------------------------
    // 3) LATEST SCANS (max 5)
    // You didn't show scan storage yet -> keep empty
    // -------------------------
    final List<Product> latestScans = [];

    return {
      'itemsToRate': itemsToRate,
      'latestPurchases': latestPurchases,
      'latestScans': latestScans,
    };
  }

  /// Submit a rating for a product
  /// rating should be: "GREAT" / "AVERAGE" / "BAD"
  Future<void> submitRating(String productId, String rating) async {
    await _purchaseHistory.setExperience(
      productId: productId,
      experience: rating,
    );
  }
}
