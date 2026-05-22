import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/destinationComponent/destinationComponentAndroid.dart';

class DestinationComponent extends StatelessWidget {
  final int design;
  final Leg leg;

  const DestinationComponent({
    super.key,
    required this.design,
    required this.leg,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return DestinationComponentAndroid(leg: leg);
      default:
        return DestinationComponentAndroid(leg: leg);
    }
  }
}