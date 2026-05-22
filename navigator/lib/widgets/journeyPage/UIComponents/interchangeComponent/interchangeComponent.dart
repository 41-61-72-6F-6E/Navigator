import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/interchangeComponent/interchangeComponentAndroid.dart';

class InterchangeComponent extends StatelessWidget {
  final int design;
  final Leg arrivingLeg;
  final Leg departingLeg;
  final String? platformChangeText;
  final bool showInterchangeTime;

  const InterchangeComponent({
    super.key,
    required this.design,
    required this.arrivingLeg,
    required this.departingLeg,
    required this.platformChangeText,
    required this.showInterchangeTime,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return InterchangeComponentAndroid(
          arrivingLeg: arrivingLeg,
          departingLeg: departingLeg,
          platformChangeText: platformChangeText,
          showInterchangeTime: showInterchangeTime,
        );
      default:
        return InterchangeComponentAndroid(
          arrivingLeg: arrivingLeg,
          departingLeg: departingLeg,
          platformChangeText: platformChangeText,
          showInterchangeTime: showInterchangeTime,
        );
    }
  }
}