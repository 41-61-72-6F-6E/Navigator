import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/markerLayer/homePageMarkerLayerAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class HomePageMarkerLayer extends StatelessWidget {
  final int design;
  final HomePageModel model;
  final String transportType;

  const HomePageMarkerLayer({
    super.key,
    required this.design,
    required this.model,
    required this.transportType,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return HomePageMarkerLayerAndroid(model: model, transportType: transportType);
      // Future designs can be added here
      default:
        return HomePageMarkerLayerAndroid(model: model, transportType: transportType);
    }
  }
}