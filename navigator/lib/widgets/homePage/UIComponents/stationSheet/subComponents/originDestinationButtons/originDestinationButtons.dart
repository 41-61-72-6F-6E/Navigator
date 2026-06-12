import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/subComponents/originDestinationButtons/originDestinationButtonsAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class originDestinationButtons extends StatelessWidget {
  final int design;
  final HomePageModel model;
  final VoidCallback onDestinationPressed;

  const originDestinationButtons({
    super.key,
    required this.design,
    required this.model,
    required this.onDestinationPressed,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return originDestinationButtonsAndroid(model: model, onDestinationPressed: onDestinationPressed);
      default:
        return originDestinationButtonsAndroid(model: model, onDestinationPressed: onDestinationPressed);
    }
  }
}