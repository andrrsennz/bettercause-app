import 'package:flutter/material.dart';
import '../../models/search_model.dart';
import '../../services/search_service.dart';
import 'product_detail_screen.dart';
import '../../services/search_history_service.dart';  // NEW
import '../../services/product_history_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _service = SearchService();
  final TextEditingController _searchController = TextEditingController();
  final SearchHistoryService _historyService = SearchHistoryService(); // FIXED
  final ProductHistoryService _productHistory = ProductHistoryService();
  List<Map<String, dynamic>> _viewedProducts = [];

  List<Product> _allProducts = [];      // browse mode products (dummy)
  List<Product> _searchResults = [];    // OFF results
  bool _isLoading = true;              // initial browse load
  bool _isSearchingRemote = false;     // OFF network loading
  String _searchQuery = '';
  String? _selectedCategory;
  final List<String> _activeFilters = [];
  String? _searchError;

  // NEW: in-memory history
  List<String> _searchHistory = [];

  final List<Map<String, dynamic>> _categories = [
    {'id': 'sweets', 'name': 'Sweets &\nChocolates', 'icon': '🍫'},
    {'id': 'beverages', 'name': 'Beverages', 'icon': '🥤'},
    {'id': 'dairy', 'name': 'Dairy\nProducts', 'icon': '🧀'},
    {'id': 'supplements', 'name': 'Supplements', 'icon': '💊'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSearchHistory();
    _loadViewedProducts();     // ⭐ NEW
  }

  Future<void> _loadViewedProducts() async {
    final items = await _productHistory.getViewedProducts();
    if (!mounted) return;
    setState(() {
      _viewedProducts = items;
    });
  }

  Future<void> _deleteViewedProduct(String id) async {
    await _productHistory.removeProduct(id);
    _loadViewedProducts();
  }



  Future<void> _loadSearchHistory() async {
    final history = await _historyService.getHistory();
    if (!mounted) return;
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveQueryToHistory(String query) async {
    await _historyService.addQuery(query);
    final history = await _historyService.getHistory();
    if (!mounted) return;
    setState(() {
      _searchHistory = history;
    });
  }


  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _service.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  // Browse-mode filtering (using dummy data)
  List<Product> get _filteredBrowseProducts {
    return _allProducts.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.brand.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool get _isSearching => _searchQuery.isNotEmpty;

  void _resetSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _activeFilters.clear();
      _searchResults = [];
      _searchError = null;
    });
  }

    Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearchingRemote = true;
      _searchError = null;
    });

    try {
      final results = await _service.searchProducts(trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });

      // ✅ record this query in history
      await _saveQueryToHistory(trimmed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Failed to search products. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSearchingRemote = false;
      });
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            // Header with Search
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF8B7FED), Color(0xFF7B6FDD)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Products',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _performSearch(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for products and brands',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: Icon(Icons.mic, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: !_isSearching
                  ? _buildBrowseMode()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBrowseMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Recent Searches
if (_searchHistory.isNotEmpty)
  Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _searchHistory.map((q) {
            return GestureDetector(
              onTap: () {
                _searchController.text = q;
                setState(() => _searchQuery = q);
                _performSearch(q);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      q,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  ),

          // Active Filters
          if (_activeFilters.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activeFilters.map((filter) {
                  return Chip(
                    label: Text(filter),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _activeFilters.remove(filter));
                    },
                    backgroundColor: Colors.grey[200],
                    labelStyle: const TextStyle(fontSize: 13),
                  );
                }).toList(),
              ),
            ),

          // Categories Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF8B7FED),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category['id'];
                    return _buildCategoryCard(category, isSelected);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ⭐ RECENTLY VIEWED PRODUCTS
          if (_viewedProducts.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recently Viewed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _viewedProducts.length,
                    itemBuilder: (context, index) {
                      final item = _viewedProducts[index];
                      return _buildRecentlyViewedItem(item);
                    },
                  ),
                ],
              ),
            ),


          
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Results Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                    children: [
                      const TextSpan(text: 'Results for '),
                      TextSpan(
                        text: '\'$_searchQuery\'',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: _resetSearch,
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: Color(0xFF8B7FED),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results List
        Expanded(
          child: Container(
            color: Colors.white,
            child: _isSearchingRemote
                ? const Center(child: CircularProgressIndicator())
                : (_searchError != null
                    ? Center(child: Text(_searchError!))
                    : (_searchResults.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return _buildProductItem(_searchResults[index]);
                            },
                          ))),
          ),
        ),
      ],
    );
  }

  // the rest of your _buildCategoryCard, _buildProductItem, _getCategoryEmoji,
  // _buildNutritionBadge, _buildEmptyState, _buildBottomNav, _buildNavItem
  // remain exactly the same as you posted.
  // (no changes needed below this comment)

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category['id'];
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B7FED) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category['icon'],
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              category['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _getCategoryEmoji(product.category),
                              style: const TextStyle(fontSize: 36),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _getCategoryEmoji(product.category),
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Nutrition Score
            _buildNutritionBadge(product.nutritionScore),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'sweets':
        return '🍫';
      case 'beverages':
        return '🥤';
      case 'dairy':
        return '🧀';
      case 'supplements':
        return '💊';
      default:
        return '📦';
    }
  }

  Widget _buildRecentlyViewedItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: item["id"]),
          ),
        ).then((_) => _loadViewedProducts()); // refresh after viewing
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            // IMAGE
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: item["imageUrl"] != null && item["imageUrl"].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item["imageUrl"],
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _getCategoryEmoji(item["category"]),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // NAME + BRAND
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["name"],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["brand"] ?? "",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // DELETE (X)
            GestureDetector(
              onTap: () => _deleteViewedProduct(item["id"]),
              child: const Icon(Icons.close, size: 20, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNutritionBadge(String score) {
    final scores = ['A', 'B', 'C', 'D', 'E'];
    final colors = {
      'A': const Color(0xFF4CAF50),
      'B': const Color(0xFF8BC34A),
      'C': const Color(0xFFFFEB3B),
      'D': const Color(0xFFFF9800),
      'E': const Color(0xFFF44336),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: scores.map((letter) {
        final isActive = letter == score;
        return Container(
          width: 20,
          height: 24,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? colors[letter] : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: isActive
                ? Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
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
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search\nor browse categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, false),
            _buildNavItem(Icons.search, true),
            _buildNavItem(Icons.shopping_cart_outlined, false),
            _buildNavItem(Icons.person_outline, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B7FED) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.grey[400],
        size: 26,
      ),
    );
  }
}
