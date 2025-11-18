import '../models/product_model.dart';

class HomeService {
  // TODO: Replace with your actual API endpoint
  static const String baseUrl = 'https://api.bettercause.com';

  /// Get all home screen data
  /// Returns items to rate (max 10), latest purchases (max 5), and latest scans (max 5)
  Future<Map<String, List<Product>>> getHomeData() async {
    // TODO: Implement actual API call
    // Example:
    // final response = await http.get(
    //   Uri.parse('$baseUrl/home'),
    //   headers: {'Authorization': 'Bearer $token'},
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   
    //   // Apply limits: 10 for ratings, 5 for purchases and scans
    //   final itemsToRate = (data['itemsToRate'] as List)
    //       .map((item) => Product.fromJson(item))
    //       .take(10)
    //       .toList();
    //   
    //   final latestPurchases = (data['latestPurchases'] as List)
    //       .map((item) => Product.fromJson(item))
    //       .take(5)
    //       .toList();
    //   
    //   final latestScans = (data['latestScans'] as List)
    //       .map((item) => Product.fromJson(item))
    //       .take(5)
    //       .toList();
    //   
    //   return {
    //     'itemsToRate': itemsToRate,
    //     'latestPurchases': latestPurchases,
    //     'latestScans': latestScans,
    //   };
    // }
    //
    // throw Exception('Failed to load home data');

    // Dummy data for testing
    await Future.delayed(const Duration(seconds: 1));

    return {
      'itemsToRate': [
        Product(
          id: '1',
          name: 'Alpro Oat Milk',
          brand: 'Oatly',
          imageUrl: 'https://example.com/alpro.jpg',
        ),
        Product(
          id: '2',
          name: 'Organic Green Tea',
          brand: 'Tea Co',
          imageUrl: 'https://example.com/tea.jpg',
        ),
      ],
      'latestPurchases': [
        Product(
          id: '3',
          name: 'Alpro Oat Milk',
          brand: 'Alpro',
          imageUrl: 'https://example.com/alpro.jpg',
          purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Product(
          id: '4',
          name: 'V-Soy Oat & Almond Milk',
          brand: 'V-Soy',
          imageUrl: 'https://example.com/vsoy.jpg',
          purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      'latestScans': [
        Product(
          id: '5',
          name: 'Alpro Oat Milk',
          brand: 'Alpro',
          imageUrl: 'https://example.com/alpro.jpg',
          scanDate: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Product(
          id: '6',
          name: 'V-Soy Oat & Almond Milk',
          brand: 'V-Soy',
          imageUrl: 'https://example.com/vsoy.jpg',
          scanDate: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ],
    };
  }

  /// Submit a rating for a product
  Future<void> submitRating(String productId, String rating) async {
    // TODO: Implement actual API call
    // Example:
    // final response = await http.post(
    //   Uri.parse('$baseUrl/ratings'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $token',
    //   },
    //   body: jsonEncode({
    //     'productId': productId,
    //     'rating': rating,
    //   }),
    // );
    //
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to submit rating');
    // }

    // Dummy implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }
}