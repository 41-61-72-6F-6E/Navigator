import 'package:flutter/material.dart';
import 'package:navigator/pages/main_navigation_page.dart';

class SharedBottomNavigation extends StatelessWidget {
  final int selectedIndex;

  const SharedBottomNavigation({
    super.key,
    this.selectedIndex = -1, // -1 means no tab is selected (for non-main pages)
  });

  @override
  Widget build(BuildContext context) {
    final NavigationService navService = NavigationService();
    
    return ValueListenableBuilder<int>(
      valueListenable: navService.currentIndex,
      builder: (context, currentIndex, child) {
        return NavigationBar(
          // If this page is a main tab, show it as selected
          // Otherwise, show the last selected main tab
          selectedIndex: selectedIndex >= 0 ? selectedIndex : currentIndex,
          onDestinationSelected: (index) {
            // When user taps, navigate back to main navigation with correct tab
            navService.navigateToMainTab(index);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
          ],
        );
      },
    );
  }
}