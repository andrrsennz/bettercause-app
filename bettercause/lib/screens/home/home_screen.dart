import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/home_service.dart';
import '../../components/home/rating_card.dart';
import '../../components/home/product_card.dart';
import '../../components/home/section_header.dart';
import '../../components/home/empty_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService();
  final PageController _ratingPageController = PageController();
  final ScrollController _purchaseScrollController = ScrollController();
  final ScrollController _scanScrollController = ScrollController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userName;
  
  List<Product> _itemsToRate = [];
  List<Product> _latestPurchases = [];
  List<Product> _latestScans = [];
  bool _isLoading = true;
  
  int _currentRatingIndex = 0;
  double _currentPurchaseOffset = 0;
  double _currentScanOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    
    // Add listeners for indicators
    _ratingPageController.addListener(() {
      setState(() {
        _currentRatingIndex = _ratingPageController.page?.round() ?? 0;
      });
    });
    
    _purchaseScrollController.addListener(() {
      setState(() {
        _currentPurchaseOffset = _purchaseScrollController.offset;
      });
    });
    
    _scanScrollController.addListener(() {
      setState(() {
        _currentScanOffset = _scanScrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _ratingPageController.dispose();
    _purchaseScrollController.dispose();
    _scanScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
  final name = await _storage.read(key: 'name');
  setState(() {
    _userName = name ?? 'User';
  });
}


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _homeService.getHomeData();
      setState(() {
        _itemsToRate = data['itemsToRate'] ?? [];
        _latestPurchases = data['latestPurchases'] ?? [];
        _latestScans = data['latestScans'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _handleRating(String productId, String rating) async {
    try {
      await _homeService.submitRating(productId, rating);
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    }
  }

  void _handleRecordPurchase() {
    Navigator.pushNamed(context, '/record_purchase');
  }

  void _handleShowMoreRatings() {
    Navigator.pushNamed(context, '/ratings');
  }

  void _handleShowMorePurchases() {
    Navigator.pushNamed(context, '/purchases');
  }

  void _handleShowMoreScans() {
    Navigator.pushNamed(context, '/scans');
  }

  void _handleProductTap(Product product) {
    Navigator.pushNamed(context, '/product_detail', arguments: product.id);
  }

  Widget _buildPageIndicator(int currentIndex, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentIndex == index 
                ? const Color(0xFF8B7FED) 
                : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildScrollIndicator(double offset, int itemCount) {
    if (itemCount <= 2) return const SizedBox.shrink();
    
    // Calculate progress (each card is 140px + 12px gap = 152px)
    final cardWidth = 152.0;
    final maxScroll = (itemCount - 2) * cardWidth;
    final progress = (offset / maxScroll).clamp(0.0, 1.0);
    
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8B7FED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header (Now scrollable!)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF4F4F4),
                          child: Icon(Icons.person, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${_userName ?? ''}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),

                              const SizedBox(height: 2),
                              Text(
                                'Track your scans and purchases today.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _handleRecordPurchase,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text(
                          'Record Purchase',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content sections
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Give Us Your Thoughts Section
                  SectionHeader(
                    title: 'Give Us Your Thoughts',
                    onShowMore: _itemsToRate.isNotEmpty ? _handleShowMoreRatings : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: _itemsToRate.isEmpty
                        ? const EmptyState(
                            message: 'No items to rate at the moment',
                          )
                        : PageView.builder(
                            controller: _ratingPageController,
                            itemCount: _itemsToRate.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: RatingCard(
                                  product: _itemsToRate[index],
                                  onRating: (rating) {
                                    _handleRating(_itemsToRate[index].id, rating);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  if (_itemsToRate.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPageIndicator(_currentRatingIndex, _itemsToRate.length),
                  ],
                  
                  const SizedBox(height: 28),
                  
                  // Your Latest Purchases Section
                  SectionHeader(
                    title: 'Your Latest Purchases',
                    onShowMore: _latestPurchases.isNotEmpty ? _handleShowMorePurchases : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _latestPurchases.isEmpty
                        ? const EmptyState(
                            message: 'No purchases yet',
                          )
                        : ListView.builder(
                            controller: _purchaseScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _latestPurchases.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ProductCard(
                                  product: _latestPurchases[index],
                                  onTap: () => _handleProductTap(_latestPurchases[index]),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_latestPurchases.length > 2)
                    _buildScrollIndicator(_currentPurchaseOffset, _latestPurchases.length),
                  
                  const SizedBox(height: 28),
                  
                  // Your Latest Scans Section
                  SectionHeader(
                    title: 'Your Latest Scans',
                    onShowMore: _latestScans.isNotEmpty ? _handleShowMoreScans : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _latestScans.isEmpty
                        ? const EmptyState(
                            message: 'No scans yet',
                          )
                        : ListView.builder(
                            controller: _scanScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _latestScans.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ProductCard(
                                  product: _latestScans[index],
                                  onTap: () => _handleProductTap(_latestScans[index]),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_latestScans.length > 2)
                    _buildScrollIndicator(_currentScanOffset, _latestScans.length),
                  
                  // Bottom padding for floating navbar
                  const SizedBox(height: 100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}