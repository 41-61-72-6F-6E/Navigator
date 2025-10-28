import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal() {
    navigatorKey = GlobalKey<NavigatorState>();
    // Initialize tab navigator keys here
    homeNavigatorKey = GlobalKey<NavigatorState>();
    savedNavigatorKey = GlobalKey<NavigatorState>();
  }

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  late GlobalKey<NavigatorState> navigatorKey;
  
  // Navigator keys for each tab - now initialized in constructor
  late final GlobalKey<NavigatorState> homeNavigatorKey;
  late final GlobalKey<NavigatorState> savedNavigatorKey;

  void setTab(int index) {
    currentIndex.value = index;
  }

  void navigateToMainTab(int index) {
    currentIndex.value = index;
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainNavigationPage()),
        (route) => false,
      );
    }
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final NavigationService _navService = NavigationService();
  
  // Create the pages once and keep them alive
  late final List<Widget> _navigators;

  @override
  void initState() {
    super.initState();
    // Initialize navigators once in initState
    _navigators = [
      _buildNavigator(
        navigatorKey: _navService.homeNavigatorKey,
        initialPage: HomePage(),
      ),
      _buildNavigator(
        navigatorKey: _navService.savedNavigatorKey,
        initialPage: SavedjourneysPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _navService.currentIndex,
      builder: (context, currentIndex, child) {
        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: _navigators, // Use the pre-built navigators
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
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

  // Creates a nested navigator for each tab
  Widget _buildNavigator({
    required GlobalKey<NavigatorState> navigatorKey,
    required Widget initialPage,
  }) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => initialPage,
          settings: settings,
        );
      },
    );
  }
}