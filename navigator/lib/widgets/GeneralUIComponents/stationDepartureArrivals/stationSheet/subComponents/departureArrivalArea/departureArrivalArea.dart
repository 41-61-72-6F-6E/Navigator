import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationSheet/subComponents/departureArrivalArea/departureArrivalAreaAndroid.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/station_sheet_notifier.dart';

class DepartureArrivalArea extends StatelessWidget {
  final int design;
  final StationSheetNotifier notifier;
  final void Function(Station station) getArrivalsForStation;
  final void Function(Station station) getDeparturesForStation;

  const DepartureArrivalArea({
    super.key,
    required this.design,
    required this.notifier,
    required this.getArrivalsForStation,
    required this.getDeparturesForStation
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return DepartureArrivalAreaAndroid(notifier: notifier,getArrivalsForStation: getArrivalsForStation, getDeparturesForStation: getDeparturesForStation,);
      default:
        return DepartureArrivalAreaAndroid(notifier: notifier,getArrivalsForStation: getArrivalsForStation, getDeparturesForStation: getDeparturesForStation,);
    }
  }
}