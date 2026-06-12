import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/loadingCircle/loadingCircle.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationSheet/subComponents/departureArrivalArea/departureArrivalArea.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/station_sheet_notifier.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/GeneralUIComponents/sheetHandle/sheetHandle.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationSheet/subComponents/originDestinationButtons/originDestinationButtons.dart';

class StationSheetAndroid extends StatelessWidget {
  final Station station;
  final ScrollController scrollController;
  final StationSheetNotifier notifier;
  final void Function(BuildContext context, Station station, bool value) onStationTapped;
  final void Function(Station station) getDeparturesForStation;
  final void Function(Station station) getArrivalsForStation;


  const StationSheetAndroid({
    super.key,
    required this.station,
    required this.scrollController,
    required this.notifier,
    required this.onStationTapped,
    required this.getDeparturesForStation,
    required this.getArrivalsForStation
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
  child: 
  Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(child: Text(station.name, style: Theme.of(context).textTheme.headlineMedium)),
      originDestinationButtons(design: 0, notifier: notifier, onTapped: onStationTapped),
      SizedBox(height: 8),
      Divider(indent: 16, endIndent: 16),
      SizedBox(height: 8),
      DepartureArrivalArea(design: 0, notifier: notifier, getArrivalsForStation: getArrivalsForStation, getDeparturesForStation: getDeparturesForStation,),
    ],
  ),
); // Placeholder content, replace with actual UI
  }
}