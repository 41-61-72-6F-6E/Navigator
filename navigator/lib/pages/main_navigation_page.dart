import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';

class NavigationService {
  // Singleton pattern - only one instance exists
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal() {
    // Initialize navigatorKey in constructor to avoid LateInitializationError
    navigatorKey = GlobalKey<NavigatorState>();
  }

  // Tracks which main tab is currently selected (0 = Home, 1 = Saved)
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  
  // Global navigator key to control navigation from anywhere
  late GlobalKey<NavigatorState> navigatorKey;

  // Call this when user taps a tab in the main navigation
  void setTab(int index) {
    currentIndex.value = index;
  }

  // Call this when user taps bottom nav from other pages
  // This returns to main navigation and selects the correct tab
  void navigateToMainTab(int index) {
    currentIndex.value = index;
    
    // Safety check to ensure navigatorKey is available
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainNavigationPage()),
        (route) => false, // Remove all previous routes
      );
    } else {
      // Fallback: This shouldn't happen, but just in case
      print('NavigatorKey not available');
    }
  }
}

class MainNavigationPage extends StatefulWidget {
  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final NavigationService _navService = NavigationService();

  // These page instances are created once and reused
  // This is what preserves the state!
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Create pages once - they'll keep their state
    _pages = [
      HomePage(),                                    // Tab 0: Home
      SavedjourneysPage(), // Tab 1: Saved
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Listen to navigation service for tab changes
    return ValueListenableBuilder<int>(
      valueListenable: _navService.currentIndex,
      builder: (context, currentIndex, child) {
        return Scaffold(
          // IndexedStack shows only one page but keeps all pages in memory
          // This preserves state (scroll positions, form data, etc.)
          body: IndexedStack(
            index: currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              // When user taps a tab, update the service
              _navService.setTab(index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up when this widget is disposed
    super.dispose();
  }
}