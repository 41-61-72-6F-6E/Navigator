import 'package:flutter/material.dart';
import 'package:navigator/models/line.dart';
import 'package:navigator/widgets/GeneralUIComponents/lineChip/lineChipAndroid.dart';

class LineChip extends StatelessWidget {
  final int design;
  final String lineName;
  final Color lineColor;
  final Color onLineColor;

  const LineChip({
    super.key,
    required this.design,
    required this.lineName,
    required this.lineColor,
    required this.onLineColor
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return LineChipAndroid(
          lineName: lineName,
          lineColor: lineColor,
          onLineColor: onLineColor,
        );
      default:
        return LineChipAndroid(
          lineName: lineName,
          lineColor: lineColor,
          onLineColor: onLineColor,
        );
    }
  }
}