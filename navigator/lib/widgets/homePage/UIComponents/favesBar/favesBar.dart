import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/favesBar/favesBarAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class FavesBar extends StatelessWidget {
  final int design;
  final HomePageModel model;

  const FavesBar({
    super.key,
    required this.design,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return FavesBarAndroid(model: model);
      // Future designs can be added here
      default:
        return FavesBarAndroid(model: model);
    }
  }
}