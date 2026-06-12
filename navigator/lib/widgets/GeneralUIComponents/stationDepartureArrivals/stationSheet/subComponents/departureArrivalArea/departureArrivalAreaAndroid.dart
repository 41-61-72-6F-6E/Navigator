import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationDepartureArrivals.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/station_sheet_notifier.dart';

class DepartureArrivalAreaAndroid extends StatelessWidget {

  final StationSheetNotifier notifier;
  final void Function(Station station) getDeparturesForStation;
  final void Function(Station station) getArrivalsForStation;

  const DepartureArrivalAreaAndroid({
    required this.notifier,
    required this.getArrivalsForStation,
    required this.getDeparturesForStation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) =>
      Column(
        children: [
          M3EToggleButtonGroup(
            type: M3EButtonGroupType.connected,
            size: M3EButtonSize.md,
            selectedIndex: notifier.getShowArrivals() ? 1 : 0,
            onSelectedIndexChanged: (index) {
              if(index == 0)
              {
                notifier.setShowDepartures(true);
                if(notifier.selectedStation != null)
                {
                  getDeparturesForStation(notifier.selectedStation!);
                }
              }
              else
              {
                notifier.setShowArrivals(true);
                if(notifier.selectedStation != null)
                {
                  getArrivalsForStation(notifier.selectedStation!);
                }
              }
            },
            actions: [
            M3EToggleButtonGroupAction(label: Text("Show Departures"), icon: Icon(Icons.call_received)),
            M3EToggleButtonGroupAction(label: Text("Show Arrivals"), icon: Icon(Icons.call_made))
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: StationDepartureArrivals(
              data: notifier.loadedDepartureArrivals,
              design: 0,
              onTripSelected: (tripId) {
                // Handle trip selection
              },
              isLoading: notifier.loading,
            ),
          ),
        ],
      ),
    );
  }
}