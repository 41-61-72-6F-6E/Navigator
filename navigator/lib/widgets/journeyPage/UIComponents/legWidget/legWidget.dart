import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/legWidget/legWidgetAndroid.dart';

class LegWidgetWrapper extends StatelessWidget {
  final int design;
  final Leg leg;
  final Color colorArg;
  final VoidCallback? onMapPressed;

  const LegWidgetWrapper({
    super.key,
    required this.design,
    required this.leg,
    required this.colorArg,
    this.onMapPressed,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return LegWidget(
          leg: leg,
          colorArg: colorArg,
          onMapPressed: onMapPressed,
        );
      default:
        return LegWidget(
          leg: leg,
          colorArg: colorArg,
          onMapPressed: onMapPressed,
        );
    }
  }
}