import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:flutter/services.dart';
import 'package:navigator/widgets/mainNavigationPage/main_navigation_page_android';
import 'package:navigator/widgets/mainNavigationPage/main_navigation_page_ios.dart';
import 'package:navigator/widgets/mainNavigationPage/main_navigation_page.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneyPage.dart';


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

  int _currentDesign = 0;

  void setTab(int index) {
    currentIndex.value = index;
  }

  void navigateToMainTab(int index) {
    currentIndex.value = index;
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainNavigationPage(design: _currentDesign)),
        (route) => false,
      );
    }
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key, required this.design});
  final int design;

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final NavigationService _navService = NavigationService();
  
  // Create the pages once and keep them alive
  late final List<Widget> _navigators;
  final GlobalKey<SavedjourneysPageState> _savedJourneysKey = GlobalKey<SavedjourneysPageState>();

  @override
  void initState() {
    super.initState();
    _navService._currentDesign = widget.design;
    // Initialize navigators once in initState
    _navigators = [
      _buildNavigator(
        navigatorKey: _navService.homeNavigatorKey,
        initialPage: HomePage(),
      ),
      _buildNavigator(
        navigatorKey: _navService.savedNavigatorKey,
        initialPage: SavedjourneysPage(design: widget.design, key: _savedJourneysKey),
      ),
    ];
  }

  void _onTabSelected(int index) {
  _navService.setTab(index);  // Still change the tab
  
  // NEW: Check if SavedJourneys tab (index 1) was selected
  if (index == 1) {
    // Trigger reload on SavedJourneysPage
    Future.microtask(() {
      _savedJourneysKey.currentState?.reloadPage();
    });
  }
}

  @override
  Widget build(BuildContext context) {
    
    return ValueListenableBuilder<int>(
      valueListenable: _navService.currentIndex,
      builder: (context, currentIndex, child) {
        Widget designImplementation;
    switch(widget.design) {
      case 0:
        designImplementation = MainNavigationPageAndroid(
          currentIndex: currentIndex, 
          onDestinationSelected: _onTabSelected,
          children: _navigators
          );
        break;
      case 1:
        designImplementation = MainNavigationPageIOS(
          currentIndex: currentIndex, 
          onDestinationSelected: _onTabSelected, 
          children: _navigators
          );
          break;
      default:
        designImplementation = MainNavigationPageAndroid(
          currentIndex: currentIndex, 
          onDestinationSelected: _onTabSelected, 
          children: _navigators
          );
    }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            
            // Get the current tab's navigator
            final navigatorKey = currentIndex == 0 
              ? _navService.homeNavigatorKey 
              : _navService.savedNavigatorKey;
            
            // Check if the current tab can pop
            final canPop = navigatorKey.currentState?.canPop() ?? false;
            
            if (canPop) {
              // Pop within the current tab
              navigatorKey.currentState?.pop();
            } else if (currentIndex != 0) {
              // If at root of non-home tab, go to home tab
              _navService.setTab(0);
            } else {
              // If at root of home tab, exit app
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: currentIndex,
              children: _navigators,
            ),
            bottomNavigationBar: designImplementation,
        )
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