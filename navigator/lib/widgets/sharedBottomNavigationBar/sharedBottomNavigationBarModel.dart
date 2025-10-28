import 'package:flutter/material.dart';

/// Model: Manages the state and navigation logic for bottom navigation
class Sharedbottomnavigationbarmodel extends ChangeNotifier {
  int _currentTabIndex = 0;
  
  // Navigation keys for each tab's stack
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
  };

  // Track the navigation history for each tab
  final Map<int, List<String>> _tabStacks = {
    0: ['/home'],
    1: ['/saved'],
  };

  int get currentTabIndex => _currentTabIndex;
  
  GlobalKey<NavigatorState> getNavigatorKey(int index) {
    return _navigatorKeys[index]!;
  }

  /// Switch to a specific tab
  void switchTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// Handle back button press - pops from current tab's stack
  Future<bool> onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentTabIndex]!.currentState;
    
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false; // Don't exit app
    }
    
    // If we're not on the first tab, switch to home tab
    if (_currentTabIndex != 0) {
      switchTab(0);
      return false;
    }
    
    return true; // Exit app
  }

  /// Push a route onto the current tab's stack
  void pushRoute(String route, {Object? arguments}) {
    final currentNavigator = _navigatorKeys[_currentTabIndex]!.currentState;
    currentNavigator?.pushNamed(route, arguments: arguments);
    _tabStacks[_currentTabIndex]?.add(route);
  }

  /// Pop current route from the current tab's stack
  void popRoute() {
    final currentNavigator = _navigatorKeys[_currentTabIndex]!.currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      _tabStacks[_currentTabIndex]?.removeLast();
    }
  }

  /// Reset a specific tab's stack to its root
  void resetTabStack(int index) {
    final navigator = _navigatorKeys[index]!.currentState;
    if (navigator != null) {
      navigator.popUntil((route) => route.isFirst);
      _tabStacks[index] = [_getInitialRoute(index)];
    }
  }

  String _getInitialRoute(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/saved';
      default:
        return '/home';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
