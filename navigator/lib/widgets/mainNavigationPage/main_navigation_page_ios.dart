import 'package:flutter/cupertino.dart';

class MainNavigationPageIOS extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final List<Widget> children;

  const MainNavigationPageIOS({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: onDestinationSelected,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.bookmark),
          label: 'Saved',
        ),
      ],
    );
  }
}