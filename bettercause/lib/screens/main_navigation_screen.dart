import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'shopping_list/shopping_list_screen.dart';
import '../../components/common/navigation_bar.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Define your screens here
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(), // TODO: Create this screen
    const ShoppingListScreen(),   // TODO: Create this screen
    const ProfileScreen(), // TODO: Create this screen
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Current screen
          _screens[_currentIndex],
          
          // Floating navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}
