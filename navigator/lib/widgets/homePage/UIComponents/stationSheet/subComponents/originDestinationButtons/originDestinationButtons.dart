import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/subComponents/originDestinationButtons/originDestinationButtonsAndroid.dart';

class originDestinationButtons extends StatelessWidget {
  final int design;
  final VoidCallback onOriginPressed;
  final VoidCallback onDestinationPressed;

  const originDestinationButtons({
    super.key,
    required this.design,
    required this.onOriginPressed,
    required this.onDestinationPressed,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return originDestinationButtonsAndroid(onOriginPressed: onOriginPressed, onDestinationPressed: onDestinationPressed);
      default:
        return originDestinationButtonsAndroid(onOriginPressed: onOriginPressed, onDestinationPressed: onDestinationPressed);
    }
  }
}