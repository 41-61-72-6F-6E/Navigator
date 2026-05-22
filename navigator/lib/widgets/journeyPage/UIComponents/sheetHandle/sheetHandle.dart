import 'package:flutter/material.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/sheetHandle/sheetHandleAndroid.dart';

class SheetHandle extends StatelessWidget {
  final int design;

  const SheetHandle({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return SheetHandleAndroid();
      default:
        return SheetHandleAndroid();
    }
  }
}