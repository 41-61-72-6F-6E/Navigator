import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/subComponents/departureArrivalArea/departureArrivalArea.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/GeneralUIComponents/sheetHandle/sheetHandle.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/subComponents/originDestinationButtons/originDestinationButtons.dart';

class StationSheetAndroid extends StatelessWidget {
  final HomePageModel model;
  final Station station;
  final ScrollController scrollController;

  const StationSheetAndroid({
    super.key,
    required this.model,
    required this.station,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(child: Text(station.name, style: Theme.of(context).textTheme.headlineMedium)),
      originDestinationButtons(design: 0, onOriginPressed: () {}, onDestinationPressed: (){}),
      SizedBox(height: 8),
      Divider(indent: 16, endIndent: 16),
      SizedBox(height: 8),
      DepartureArrivalArea(design: 0, layers: model.stationSheetNotifier),
    ],
  ),
); // Placeholder content, replace with actual UI
  }
}