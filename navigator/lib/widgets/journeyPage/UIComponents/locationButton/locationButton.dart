import 'package:flutter/material.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/locationButton/locationButtonAndroid.dart';

class LocationButton extends StatelessWidget {
  final int design;
  final VoidCallback onPressed;

  const LocationButton({
    super.key,
    required this.design,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return LocationButtonAndroid(onPressed: onPressed);
      default:
        return LocationButtonAndroid(onPressed: onPressed);
    }
  }
}