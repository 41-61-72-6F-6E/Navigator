import 'package:flutter/material.dart';
import 'package:navigator/widgets/GeneralUIComponents/loadingCircle/loadingCircleAndroid.dart';

class LoadingCircle extends StatelessWidget {
  final int design;

  const LoadingCircle({
    super.key,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return LoadingCircleAndroid();
      default:
        return LoadingCircleAndroid();
    }
  }
}