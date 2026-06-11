import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/subComponents/departureArrivalArea/departureArrivalAreaAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/homePage/notifiers/station_sheet_notifier.dart';

class DepartureArrivalArea extends StatelessWidget {
  final int design;
  final StationSheetNotifier layers;
  final HomePageModel model;

  const DepartureArrivalArea({
    super.key,
    required this.design,
    required this.layers,
    required this.model
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return DepartureArrivalAreaAndroid(layers: layers,model: model);
      default:
        return DepartureArrivalAreaAndroid(layers: layers,model: model,);
    }
  }
}