import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/walkingLeg/walkingLegAndroid.dart';

class WalkingLeg extends StatelessWidget {
  final int design;
  final Leg leg;
  final VoidCallback onMapPressed;

  const WalkingLeg({
    super.key,
    required this.design,
    required this.leg,
    required this.onMapPressed,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return WalkingLegAndroid(leg: leg, onMapPressed: onMapPressed);
      default:
        return WalkingLegAndroid(leg: leg, onMapPressed: onMapPressed);
    }
  }
}