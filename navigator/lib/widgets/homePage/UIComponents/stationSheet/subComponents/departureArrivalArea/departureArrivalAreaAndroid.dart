import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:navigator/widgets/homePage/notifiers/map_layers_notifier.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationDepartureArrivals.dart';
import 'package:navigator/widgets/homePage/notifiers/station_sheet_notifier.dart';

class DepartureArrivalAreaAndroid extends StatelessWidget {

  final StationSheetNotifier layers;

  const DepartureArrivalAreaAndroid({
    required this.layers,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: layers,
      builder: (context, _) =>
      Column(
        children: [
          M3EToggleButtonGroup(
            type: M3EButtonGroupType.connected,
            size: M3EButtonSize.md,
            selectedIndex: layers.getShowArrivals() ? 1 : 0,
            onSelectedIndexChanged: (index) {
              if(index == 0)
              {
                layers.setShowDepartures(true);
              }
              else
              {
                layers.setShowArrivals(true);
              }
            },
            actions: [
            M3EToggleButtonGroupAction(label: Text("Show Departures"), icon: Icon(Icons.call_received)),
            M3EToggleButtonGroupAction(label: Text("Show Arrivals"), icon: Icon(Icons.call_made))
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: StationDepartureArrivals(
              data: layers.loadedDepartureArrivals,
              design: 0,
              onTripSelected: (tripId) {
                // Handle trip selection
              },
            ),
          ),
        ],
      ),
    );
  }
}