import 'package:flutter/material.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/emptyState/emptyStateAndroid.dart';

class EmptyState extends StatelessWidget {
  final int design;

  const EmptyState({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return EmptyStateAndroid();
      default:
        return EmptyStateAndroid();
    }
  }
}