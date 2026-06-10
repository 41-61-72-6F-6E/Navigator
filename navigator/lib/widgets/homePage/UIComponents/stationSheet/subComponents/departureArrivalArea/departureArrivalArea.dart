import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/subComponents/departureArrivalArea/departureArrivalAreaAndroid.dart';
import 'package:navigator/widgets/homePage/notifiers/station_sheet_notifier.dart';

class DepartureArrivalArea extends StatelessWidget {
  final int design;
  final StationSheetNotifier layers;

  const DepartureArrivalArea({
    super.key,
    required this.design,
    required this.layers,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return DepartureArrivalAreaAndroid(layers: layers,);
      default:
        return DepartureArrivalAreaAndroid(layers: layers);
    }
  }
}