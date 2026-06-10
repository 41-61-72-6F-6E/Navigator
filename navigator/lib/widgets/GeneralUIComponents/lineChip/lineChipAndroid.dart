import 'package:flutter/material.dart';

class LineChipAndroid extends StatelessWidget {
  final String lineName;
  final Color lineColor;
  final Color onLineColor;

  const LineChipAndroid({super.key, required this.lineName, required this.lineColor, required this.onLineColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lineName,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(color: onLineColor),
      ),
    );
  }
}
