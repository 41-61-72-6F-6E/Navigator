import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/originComponent/originComponentAndroid.dart';

class OriginComponent extends StatelessWidget {
  final int design;
  final Leg leg;

  const OriginComponent({
    super.key,
    required this.design,
    required this.leg,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return OriginComponentAndroid(leg: leg);
      default:
        return OriginComponentAndroid(leg: leg);
    }
  }
}