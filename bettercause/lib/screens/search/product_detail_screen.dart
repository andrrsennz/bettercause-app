import 'package:flutter/material.dart';
import '../../models/search_model.dart';
import '../../services/search_service.dart';
import '../../services/product_history_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SearchService _service = SearchService();
  Product? _product;
  bool _isLoading = true;
  final ProductHistoryService _history = ProductHistoryService();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await _service.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
      if (product != null) {
        await _history.addViewedProduct({
          "id": product.id,
          "name": product.name,
          "brand": product.brand,
          "imageUrl": product.imageUrl,
          "category": product.category,
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product: $e')),
        );
      }
    }
  }

  void _showMarketplaceModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Purchase Through Your Local Marketplaces',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We will redirect you to one of these\nmarketplaces',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Shopee',
                              style: TextStyle(
                                  color: Color(0xFFEE4D2D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('tokopedia',
                              style: TextStyle(
                                  color: Color(0xFF03AC0E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToShoppingListModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add New Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                  'Are you sure you want to add this item on\nyour shopping list?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _service.addToShoppingList(widget.productId);
                        if (mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/shopping-list');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Add Item'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackPurchaseModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Did you purchase this item?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_product != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _product!.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(_product!.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                            return Center(
                                child: Text(_getCategoryEmoji(_product!.category),
                                    style: const TextStyle(fontSize: 80)));
                          }))
                      : Center(
                          child: Text(_getCategoryEmoji(_product!.category),
                              style: const TextStyle(fontSize: 80))),
                ),
              const SizedBox(height: 24),
              const Text(
                  'Update your purchase record for better\nfuture suggestions.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home', (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Track purchase'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('I didn\'t buy it'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ========= PRODUCT IMAGE =========
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: _product!.imageUrl.isNotEmpty
                      ? Image.network(_product!.imageUrl, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(_getCategoryEmoji(_product!.category),
                                    style: const TextStyle(fontSize: 60))),
                          );
                        })
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text(_getCategoryEmoji(_product!.category),
                                  style: const TextStyle(fontSize: 60)))),
                ),
              ),
            ),

            // ========= PRODUCT NAME & BRAND =========
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  Text(_product!.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(_product!.brand,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),

            // ========= BADGES =========
            if (_product!.isVegan || _product!.isEcoFriendly)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_product!.isVegan)
                      _buildBadge('Vegan', Icons.eco, const Color(0xFF4CAF50)),
                    if (_product!.isEcoFriendly)
                      _buildBadge('Eco-friendly', Icons.water_drop, 
                          const Color(0xFF2196F3)),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // ========= MATCH PERCENTAGE =========
            if (_product!.matchPercentage > 0)
              _buildCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 15),
                        children: [
                          TextSpan(
                            text: '${_product!.matchPercentage}% ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const TextSpan(
                              text: 'Matched for you',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8E3FF),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Text('Great',
                          style: TextStyle(
                              fontSize: 11, 
                              color: Color(0xFF6B4CE6),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            // ========= AI ANALYSIS =========
            _buildCard(
              title: 'AI Analysis',
              icon: Icons.auto_awesome,
              iconColor: const Color(0xFF6B4CE6),
              child: const Text(
                'Oatly Oat Drink is a well-formulated plant-based milk alternative with a good fortification and low saturated fat. It also has lower protein content than soy milk, so it may not be ideal for consumers looking for a dairy alternative with high protein.',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
            ),

            // ========= IDEAL FOR & NUTRITION (SIDE BY SIDE) =========
            _buildCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IDEAL FOR
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ideal For',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        _product!.idealFor.isNotEmpty
                            ? Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: _product!.idealFor
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFF3E8FF),
                                              borderRadius: BorderRadius.circular(14)),
                                          child: Text(tag,
                                              style: const TextStyle(
                                                  fontSize: 10, color: Color(0xFF6B4CE6))),
                                        ))
                                    .toList(),
                              )
                            : const Text('No information',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // NUTRITION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nutrition',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Color(0xFFFF6B35), size: 16),
                            const SizedBox(width: 4),
                            Text('${_product!.calories}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            const Text('Calories',
                                style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_product!.protein.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                                const Text('Protein',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_product!.fat.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                                const Text('Fat',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ========= ETHICS SCORE =========
            _buildCard(
              title: 'Ethics Score',
              trailing: Text('${_product!.ethicsScore}/100',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              child: _product!.ethicsScore > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('AI Calculation',
                                style: TextStyle(fontSize: 11, color: Color(0xFF6B4CE6))),
                            SizedBox(width: 4),
                            Icon(Icons.auto_awesome, size: 11, color: Color(0xFF6B4CE6)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _product!.ethicsScore / 100,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _getEthicsColor(_product!.ethicsScore)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEthicsRow('Environmental Impact', _product!.environmentalImpact),
                        const SizedBox(height: 8),
                        _buildEthicsRow('Animal Welfare', _product!.animalWelfare),
                        const SizedBox(height: 8),
                        _buildEthicsRow('Fair Labor', _product!.fairLabor),
                      ],
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= INGREDIENTS (NOT SCROLLABLE, HIDDEN OVERFLOW) =========
            _buildCard(
              title: 'Ingredients Breakdown',
              child: _product!.ingredients.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _product!.ingredients
                              .take(6)
                              .map((ing) => _buildIngredientChip(ing.name, ing.status))
                              .toList(),
                        ),
                        if (_product!.ingredients.length > 6)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // TODO: Show full ingredients modal
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B4CE6),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= POSITIVES =========
            _buildCard(
              title: 'Positives',
              child: _product!.positives.isNotEmpty
                  ? Column(
                      children: _product!.positives
                          .map((positive) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildNutrientRow(
                                  positive.name,
                                  positive.value,
                                  positive.details,
                                  isPositive: true,
                                ),
                              ))
                          .toList(),
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= NEGATIVES =========
            _buildCard(
              title: 'Negatives',
              child: _product!.negatives.isNotEmpty
                  ? Column(
                      children: _product!.negatives
                          .map((negative) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildNutrientRow(
                                  negative.name,
                                  negative.value,
                                  negative.details,
                                  isPositive: false,
                                ),
                              ))
                          .toList(),
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // ========= CERTIFICATIONS =========
            _buildCard(
              title: 'Certifications',
              child: _product!.certifications.isNotEmpty
                  ? Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _product!.certifications
                          .take(6)
                          .map((cert) => _buildCertBadge(_getCertificationEmoji(cert)))
                          .toList(),
                    )
                  : const Text('No information',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomSheet: _buildBottomButtons(),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddToShoppingListModal,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: const Text('Add to Shop List', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showTrackPurchaseModal,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Record Purchase', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showMarketplaceModal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Purchase Online',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    String? title,
    Widget? trailing,
    IconData? icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      if (icon != null) ...[
                        const SizedBox(width: 4),
                        Icon(icon, size: 14, color: iconColor),
                      ],
                    ],
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildEthicsRow(String label, String value) {
    Color dotColor = Colors.grey;
    if (value.toLowerCase().contains('low') ||
        value.toLowerCase().contains('excellent') ||
        value.toLowerCase().contains('certified')) {
      dotColor = const Color(0xFF4CAF50);
    } else if (value.toLowerCase().contains('moderate') ||
        value.toLowerCase().contains('good')) {
      dotColor = const Color(0xFFFFA726);
    } else if (value.toLowerCase().contains('high') ||
        value.toLowerCase().contains('contains')) {
      dotColor = const Color(0xFFFF4444);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Row(
          children: [
            Icon(Icons.circle, color: dotColor, size: 6),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientRow(String name, String value, List<String>? details,
      {required bool isPositive}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.warning,
              color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
            Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        if (details != null && details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details
                  .map((detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text('• $detail',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildIngredientChip(String name, String status) {
    Color color, bgColor;
    IconData? icon;
    switch (status.toLowerCase()) {
      case 'reduced':
        color = const Color(0xFFFF4444);
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.flag;
        break;
      case 'monitored':
        color = const Color(0xFFFFA726);
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.warning_amber;
        break;
      default:
        color = Colors.grey;
        bgColor = const Color(0xFFF5F5F5);
        icon = null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              name,
              style: TextStyle(fontSize: 10, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertBadge(String emoji) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
    );
  }

  Color _getEthicsColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFFF4444);
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
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

  String _getCertificationEmoji(String cert) {
    if (cert.contains('nutriscore')) return '📊';
    if (cert.contains('ecoscore')) return '🌍';
    if (cert.contains('organic')) return '🌿';
    if (cert.contains('vegan')) return '🌱';
    if (cert.contains('fair-trade')) return '⚖️';
    if (cert.contains('gluten-free')) return '🌾';
    if (cert.contains('palm-oil-free')) return '🌴';
    return '✓';
  }
}
