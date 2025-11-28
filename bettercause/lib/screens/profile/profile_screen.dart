import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';
import '../../services/user_profile_service.dart';
import '../../components/profile/profile_stat_card.dart';
import '../../components/profile/personal_value_item.dart';
import '../../components/profile/category_preference_card.dart';
import '../../components/profile/menu_item_card.dart';
import 'category_preferences_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _selectedTab = 'Personal Values';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // TODO: Get actual user ID from auth service
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.userId == null) {
        throw Exception("No logged-in user found");
      }

      final profile = await _profileService.getUserProfile(auth.userId!);

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updatePersonalValue(String key, bool value) async {
  if (_userProfile == null) return;

  final updatedValues = Map<String, bool>.from(_userProfile!.personalValues);
  final oldValue = updatedValues[key] ?? false;
  updatedValues[key] = value;

  setState(() {
    _userProfile = _userProfile!.copyWith(personalValues: updatedValues);
  });

  try {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await _profileService.updatePersonalValue(auth.userId!, key, value);

    if (!ok && mounted) {
      // revert on failure
      updatedValues[key] = oldValue;
      setState(() {
        _userProfile = _userProfile!.copyWith(personalValues: updatedValues);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save preference')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    // revert on error
    updatedValues[key] = oldValue;
    setState(() {
      _userProfile = _userProfile!.copyWith(personalValues: updatedValues);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating preference: $e')),
    );
  }
}


  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // TODO: Get actual user ID from auth service
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await _profileService.logout(auth.userId!);
        auth.logout();  // also reset provider session

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9C6FDE),
              Color(0xFF7B9FFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProfileHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildPersonalizationSection(),
                          const SizedBox(height: 24),
                          _buildNeedHelpSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Member since ${_userProfile!.memberSince}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ProfileStatCard(
                  value: _userProfile!.productScans.toString(),
                  label: 'Product Scans',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileStatCard(
                  value: _userProfile!.productsPurchased.toString(),
                  label: 'Products Purchased',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalization',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTabSelector(),
              const SizedBox(height: 20),
              if (_selectedTab == 'Personal Values')
                _buildPersonalValuesContent()
              else
                _buildNeedsPreferencesContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('Personal Values'),
          ),
          Expanded(
            child: _buildTab('Needs & Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalValuesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Core Values',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'These will be applied to all product categories',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        PersonalValueItem(
          icon: '🌱',
          label: 'Vegan',
          description: 'Vegan Products',
          badgeColor: const Color(0xFF4CAF50),
          value: _userProfile!.personalValues['vegan'] ?? false,
          onChanged: (value) => _updatePersonalValue('vegan', value),
        ),
        PersonalValueItem(
          icon: '🐰',
          label: 'Cruelty-free',
          description: 'Cruelty-free',
          badgeColor: const Color(0xFFE91E63),
          value: _userProfile!.personalValues['cruelty_free'] ?? false,
          onChanged: (value) => _updatePersonalValue('cruelty_free', value),
        ),
        PersonalValueItem(
          icon: '🌿',
          label: 'Organic',
          description: 'Naturally Sourced',
          badgeColor: const Color(0xFF8BC34A),
          value: _userProfile!.personalValues['organic'] ?? false,
          onChanged: (value) => _updatePersonalValue('organic', value),
        ),
        PersonalValueItem(
          icon: '🌍',
          label: 'Eco-friendly',
          description: 'Eco-Friendly',
          badgeColor: const Color(0xFF00BCD4),
          value: _userProfile!.personalValues['eco_friendly'] ?? false,
          onChanged: (value) => _updatePersonalValue('eco_friendly', value),
        ),
        PersonalValueItem(
          icon: '☪️',
          label: 'Halal',
          description: 'Halal Only',
          badgeColor: const Color(0xFF4CAF50),
          value: _userProfile!.personalValues['halal'] ?? false,
          onChanged: (value) => _updatePersonalValue('halal', value),
        ),
        PersonalValueItem(
          icon: '👷',
          label: 'Fair Labor',
          description: 'Fair Trade Labor',
          badgeColor: const Color(0xFFFF9800),
          value: _userProfile!.personalValues['fair_labor'] ?? false,
          onChanged: (value) => _updatePersonalValue('fair_labor', value),
        ),
      ],
    );
  }

  Widget _buildNeedsPreferencesContent() {
    final foodCount = _userProfile!.categoryPreferences.preferencesCount['food_beverages'] ?? 0;
    final beautyCount = _userProfile!.categoryPreferences.preferencesCount['beauty_care'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Customer needs for each product type',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        CategoryPreferenceCard(
          icon: '🍔',
          title: 'Food & Beverages',
          subtitle: foodCount > 0 
              ? '$foodCount of 11 preferences set'
              : 'No preferences set yet',
          iconBackgroundColor: const Color(0xFFFF9800),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryPreferencesScreen(
                  categoryType: 'food_beverages',
                  categoryName: 'Food & Beverages',
                  categoryIcon: '🍔',
                  categoryColor: Color(0xFFFF9800),
                ),
              ),
            );
          },
        ),
        CategoryPreferenceCard(
          icon: '💄',
          title: 'Beauty & Care',
          subtitle: beautyCount > 0 
              ? '$beautyCount preferences set'
              : 'No preferences set yet',
          iconBackgroundColor: const Color(0xFFE91E63),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryPreferencesScreen(
                  categoryType: 'beauty_care',
                  categoryName: 'Beauty & Care',
                  categoryIcon: '💄',
                  categoryColor: Color(0xFFE91E63),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNeedHelpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Need Help?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        MenuItemCard(
          icon: Icons.chat_bubble_outline,
          title: 'Give Us Your Feedback',
          onTap: () {
            // TODO: Navigate to feedback screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback - Coming soon!')),
            );
          },
        ),
        MenuItemCard(
          icon: Icons.share_outlined,
          title: 'Share Our App',
          onTap: () {
            // TODO: Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share - Coming soon!')),
            );
          },
        ),
        MenuItemCard(
          icon: Icons.lock_outline,
          title: 'Privacy Policy',
          onTap: () {
            // TODO: Navigate to privacy policy screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Policy - Coming soon!')),
            );
          },
        ),
        MenuItemCard(
          icon: Icons.description_outlined,
          title: 'Terms of Use',
          onTap: () {
            // TODO: Navigate to terms of use screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms of Use - Coming soon!')),
            );
          },
        ),
        const SizedBox(height: 8),
        MenuItemCard(
          icon: Icons.info_outline,
          title: 'About Us',
          onTap: () {
            // TODO: Navigate to about us screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('About Us - Coming soon!')),
            );
          },
        ),
        const SizedBox(height: 8),
        MenuItemCard(
          icon: Icons.logout,
          title: 'Log out',
          onTap: _handleLogout,
        ),
      ],
    );
  }
}