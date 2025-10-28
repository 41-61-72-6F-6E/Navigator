import 'package:flutter/material.dart';
import 'package:navigator/widgets/sharedBottomNavigationBar/sharedBottomNavigationBarVIewMaterial3.dart';

/// View: The bottom navigation bar widget
class SharedBottomNavigationBarView extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final int design;

  const SharedBottomNavigationBarView({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    switch(design)
    {
      case 0: 
        return SharedBottomNavigationBarViewMaterial3(currentIndex: currentIndex, onTabSelected: onTabSelected);
      default:
        return SharedBottomNavigationBarViewMaterial3(currentIndex: currentIndex, onTabSelected: onTabSelected);
    }
  }
}
