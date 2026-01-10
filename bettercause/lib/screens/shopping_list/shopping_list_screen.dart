// lib/screens/shopping_list/shopping_list_screen.dart

import 'package:flutter/material.dart';

import '../../models/shopping_item_model.dart';
import '../../services/shopping_list_service.dart';
import '../search/product_detail_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _service = ShoppingListService();

  final TextEditingController _searchController = TextEditingController();

  List<ShoppingItem> _items = [];
  bool _loading = true;

  String _search = '';
  String _selectedCategory = 'All Categories';
  final List<String> _categories = const [
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await _service.getShoppingList();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<ShoppingItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'All Categories' ||
          item.category == _selectedCategory;

      final q = _search.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.brand.toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _totalItems => _filteredItems.length;

  int get _totalBought =>
      _filteredItems.where((x) => x.isBought).toList().length;

  int get _totalNeeded => _totalItems - _totalBought;

  Future<void> _toggleBought(String id) async {
    await _service.toggleItemStatus(id);
    await _loadItems();
  }

  Future<void> _deleteItem(String id) async {
    await _service.deleteItem(id);
    await _loadItems();
  }

  void _openProductDetail(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    ).then((_) => _loadItems());
  }

  // ---------- Manual Add Dialog ----------
  Future<void> _showAddManualDialog() async {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    String category = 'Food & Beverages';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            TextField(
              controller: brandCtrl,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              items: _categories
                  .where((c) => c != 'All Categories')
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => category = v ?? category,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _service.addManualItem(
      name: nameCtrl.text,
      brand: brandCtrl.text,
      category: category,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added ✅')),
    );

    await _loadItems();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (_, i) {
                            return _buildItemCard(_filteredItems[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF8B7FED), Color(0xFF7B6FDD)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showAddManualDialog,
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', _totalItems.toString(), Icons.list_alt),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('Needed', _totalNeeded.toString(), Icons.shopping_cart_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('Bought', _totalBought.toString(), Icons.check_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // category filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCategory = v ?? 'All Categories';
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    )),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item) {
    return GestureDetector(
      onTap: () {
        // only open detail for OFF items (barcode numeric). Manual items won't exist in OFF.
        final isOffBarcode = RegExp(r'^\d+$').hasMatch(item.id);
        if (isOffBarcode) _openProductDetail(item.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildImage(item),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(item)),
            const SizedBox(width: 10),
            _buildActions(item),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ShoppingItem item) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: item.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
              ),
            )
          : const Icon(Icons.shopping_bag_outlined),
    );
  }

  Widget _buildInfo(ShoppingItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            decoration: item.isBought ? TextDecoration.lineThrough : null,
            color: item.isBought ? Colors.grey : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.brand,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.category,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B4CE6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ShoppingItem item) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _toggleBought(item.id),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.isBought ? const Color(0xFF4CAF50) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: item.isBought ? Colors.white : Colors.grey[700],
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _deleteItem(item.id),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFFF4444),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined,
                  size: 56, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your shopping list is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from Product Detail or tap + to add manually.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddManualDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          ],
        ),
      ),
    );
  }
}
