import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/UIComponents/markerLayer/homePageMarkerLayerAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class HomePageMarkerLayer extends StatelessWidget {
  final int design;
  final HomePageModel model;
  final String transportType;
  final void Function(Station) onStationTap;

  const HomePageMarkerLayer({
    super.key,
    required this.design,
    required this.model,
    required this.transportType,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return HomePageMarkerLayerAndroid(model: model, transportType: transportType, onStationTap: onStationTap);
      // Future designs can be added here
      default:
        return HomePageMarkerLayerAndroid(model: model, transportType: transportType, onStationTap: onStationTap);
    }
  }
}