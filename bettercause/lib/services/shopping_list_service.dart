import '../models/shopping_item_model.dart';

class ShoppingListService {
  static const String baseUrl = 'https://api.bettercause.com';

  Future<List<ShoppingItem>> getShoppingList() async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));

    // Dummy data
    return [
      ShoppingItem(
        id: '1',
        name: 'Organic Almond Milk',
        brand: 'Pacific Foods',
        imageUrl: '',
        category: 'Food & Beverages',
        isBought: false,
        addedDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ShoppingItem(
        id: '2',
        name: 'Vitamin C Brightening Serum',
        brand: 'The Body Shop',
        imageUrl: '',
        category: 'Beauty & Care',
        isBought: false,
        addedDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ShoppingItem(
        id: '3',
        name: 'Moisturizer',
        brand: 'The Body Shop',
        imageUrl: '',
        category: 'Beauty & Care',
        isBought: true,
        addedDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ShoppingItem(
        id: '4',
        name: 'Oatly Oat Milk',
        brand: 'Oatly',
        imageUrl: '',
        category: 'Food & Beverages',
        isBought: true,
        addedDate: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  Future<void> toggleItemStatus(String itemId) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> deleteItem(String itemId) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> addItem(ShoppingItem item) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(milliseconds: 500));
  }
}