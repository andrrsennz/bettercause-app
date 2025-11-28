import 'package:flutter/material.dart';
import '../../models/category_preference_model.dart';
import '../../services/category_preference_service.dart';
import '../../components/profile/category_preference_toggle_item.dart';
import '../../components/profile/category_preference_section_header.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CategoryPreferencesScreen extends StatefulWidget {
  final String categoryType;
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;

  const CategoryPreferencesScreen({
    super.key,
    required this.categoryType,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<CategoryPreferencesScreen> createState() =>
      _CategoryPreferencesScreenState();
}

class _CategoryPreferencesScreenState extends State<CategoryPreferencesScreen> {
  final CategoryPreferenceService _service = CategoryPreferenceService();
  CategoryPreferenceData? _foodPreferences;
  CategoryPreferenceData? _beautyPreferences;
  bool _isLoading = true;
  String _selectedTab = 'Food & Beverages';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.categoryName;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Get actual user ID from auth service
      // Load Food & Beverages preferences
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final foodPrefs = await _service.getCategoryPreferences(
        auth.userId!,
        'food_beverages',
      );

      setState(() {
        _foodPreferences = foodPrefs;
        _isLoading = false;
      });

      // Beauty & Care will be loaded when implemented
      // For now, we don't load it
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference(
    int sectionIndex,
    int optionIndex,
    bool value,
  ) async {
    if (_foodPreferences == null) return;

    final option = _foodPreferences!.sections[sectionIndex].options[optionIndex];

    setState(() {
      option.isEnabled = value;
    });

    try {
      // TODO: Get actual user ID from auth service
      final auth = Provider.of<AuthProvider>(context, listen: false);

      await _service.updateCategoryPreference(
        auth.userId!,
        'food_beverages',
        option.title,
        value,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating preference: $e')),
        );
      }
    }
  }

  void _switchTab(String tabName) {
    setState(() {
      _selectedTab = tabName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Customize needs for each product type',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTabSelector(),
          Expanded(
            child: _selectedTab == 'Food & Beverages'
                ? _buildPreferencesContent()
                : _buildComingSoonContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildTabChip(
            icon: '🍔',
            label: 'Food & Beverages',
          ),
          const SizedBox(width: 12),
          _buildTabChip(
            icon: '💄',
            label: 'Beauty & Care',
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String icon,
    required String label,
  }) {
    final isSelected = _selectedTab == label;

    return GestureDetector(
      onTap: () {
        _switchTab(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_foodPreferences == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error loading preferences'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPreferences,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryPreferencesHeader(),
            _buildPreferenceSections(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPreferencesHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Category Preferences',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPreferenceSections() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int sectionIndex = 0;
              sectionIndex < _foodPreferences!.sections.length;
              sectionIndex++)
            if (_foodPreferences!.sections[sectionIndex].options.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryPreferenceSectionHeader(
                    title: _foodPreferences!.sections[sectionIndex].sectionTitle,
                    isFirst: sectionIndex == 1,
                  ),
                  for (int optionIndex = 0;
                      optionIndex <
                          _foodPreferences!.sections[sectionIndex].options.length;
                      optionIndex++)
                    CategoryPreferenceToggleItem(
                      title: _foodPreferences!
                          .sections[sectionIndex].options[optionIndex].title,
                      description: _foodPreferences!
                          .sections[sectionIndex].options[optionIndex].description,
                      value: _foodPreferences!
                          .sections[sectionIndex].options[optionIndex].isEnabled,
                      onChanged: (value) =>
                          _updatePreference(sectionIndex, optionIndex, value),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildComingSoonContent() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'This feature\'s in progress.\nKeep an eye out for future updates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}