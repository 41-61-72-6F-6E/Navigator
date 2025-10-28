import 'package:flutter/material.dart';

/// View: The bottom navigation bar widget
class SharedBottomNavigationBarViewMaterial3 extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const SharedBottomNavigationBarViewMaterial3({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTabSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
      ],
    );
  }
}
