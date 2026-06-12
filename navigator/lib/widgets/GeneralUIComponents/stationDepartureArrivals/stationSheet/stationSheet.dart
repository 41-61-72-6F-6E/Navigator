import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/station_sheet_notifier.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationSheet/stationSheetAndroid.dart';

class StationSheet {
  final int design;
  final StationSheetNotifier notifier;
  final Station station;
  final void Function(BuildContext context, Station station, bool value) onStationTapped;
  final void Function(Station station) getDeparturesForStation;
  final void Function(Station station) getArrivalsForStation;

  const StationSheet({
    required this.design,
    required this.notifier,
    required this.station,
    required this.onStationTapped,
    required this.getArrivalsForStation,
    required this.getDeparturesForStation
  });

  @override
  static Future<T?> show<T>(
    BuildContext context,
    StationSheetNotifier notifier,
    int design,
    Station station,
    final void Function(BuildContext context, Station station, bool value) onStationTapped,
    final void Function(Station station) getDeparturesForStation,
    final void Function(Station station) getArrivalsForStation
  ) {
    switch (design) {
      case 0:
        return showModalBottomSheet<T>(
          showDragHandle: true,
          context: context,
          isScrollControlled: true, // allows full height control
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            builder: (context, scrollController) => ListenableBuilder(
              listenable: notifier,
              builder: (context, child) => StationSheetAndroid(
                notifier: notifier,
                onStationTapped: onStationTapped,
                getArrivalsForStation: getArrivalsForStation,
                getDeparturesForStation: getDeparturesForStation,
                station: station,
                scrollController: scrollController, // pass it down
              ),
            ),
          ),
        );
      // Future designs can be added here
      default:
        return showModalBottomSheet<T>(
          showDragHandle: true,
          context: context,
          isScrollControlled: true, // allows full height control
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            builder: (context, scrollController) => ListenableBuilder(
              listenable: notifier,
              builder: (context, child) => StationSheetAndroid(
                notifier: notifier,
                onStationTapped: onStationTapped,
                getArrivalsForStation: getArrivalsForStation,
                getDeparturesForStation: getDeparturesForStation,
                station: station,
                scrollController: scrollController, // pass it down
              ),
            ),
          ),
        );
  
}
  }}
