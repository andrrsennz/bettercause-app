import 'package:flutter/material.dart';
import '../../models/shopping_item_model.dart';
import '../../services/shopping_list_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _service = ShoppingListService();
  List<ShoppingItem> _allItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Items';
  String _selectedCategory = 'All Categories';

  final List<String> _categories = [
    'All Categories',
    'Food & Beverages',
    'Beauty & Care',
    'Household',
    'Electronics',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getShoppingList();
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  List<ShoppingItem> get _filteredItems {
    var items = _allItems;

    // Filter by status
    if (_selectedFilter == 'Needed') {
      items = items.where((item) => !item.isBought).toList();
    } else if (_selectedFilter == 'Bought') {
      items = items.where((item) => item.isBought).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All Categories') {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }

    return items;
  }

  int get _totalItems => _allItems.length;
  int get _completedItems => _allItems.where((item) => item.isBought).length;
  int get _neededCount => _allItems.where((item) => !item.isBought).length;
  int get _boughtCount => _allItems.where((item) => item.isBought).length;

  Future<void> _toggleItemStatus(String itemId) async {
    try {
      await _service.toggleItemStatus(itemId);
      setState(() {
        final index = _allItems.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          _allItems[index] = _allItems[index].copyWith(
            isBought: !_allItems[index].isBought,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _service.deleteItem(itemId);
      setState(() {
        _allItems.removeWhere((item) => item.id == itemId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _showProductDetail(String itemId) {
    Navigator.pushNamed(context, '/product_detail', arguments: itemId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B7FED), Color(0xFF6B5FDB)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B7FED).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Shopping List',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Add new item
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _totalItems == 0
                        ? 'You currently have no items on your list'
                        : '$_completedItems out of $_totalItems completed',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_totalItems > 0) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _totalItems > 0 ? _completedItems / _totalItems : 0,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildFilterChip('All Items ($_totalItems)', 'All Items'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Needed ($_neededCount)', 'Needed'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Bought ($_boughtCount)', 'Bought'),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Category Filter
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (category != 'All Categories')
                            Text(_getCategoryEmoji(category)),
                          if (category != 'All Categories') const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF8B7FED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF8B7FED) : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Items List
            Expanded(
              child: _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(_filteredItems[index]);
                      },
                    ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF8B7FED) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Food & Beverages':
        return '🍔';
      case 'Beauty & Care':
        return '💄';
      case 'Household':
        return '🏠';
      case 'Electronics':
        return '📱';
      default:
        return '📦';
    }
  }

  Widget _buildItemCard(ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => _toggleItemStatus(item.id),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isBought ? const Color(0xFF8B7FED) : Colors.white,
                  border: Border.all(
                    color: item.isBought ? const Color(0xFF8B7FED) : const Color(0xFFD1D1D1),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: item.isBought
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ),

          // Product Image
          Container(
            width: 70,
            height: 70,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey);
                      },
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey),
          ),

          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      decoration: item.isBought ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // See More Button
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () => _showProductDetail(item.id),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF3D3D3D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See more',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Delete Button
          if (item.isBought)
            IconButton(
              onPressed: () => _deleteItem(item.id),
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              padding: const EdgeInsets.all(8),
            ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.shopping_basket_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Items Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All Items'
                ? 'You currently have no items on your shopping list.\nDiscover products around you!'
                : 'No items in this category.\nTry a different filter!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to search/discover
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7FED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Search Product',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}