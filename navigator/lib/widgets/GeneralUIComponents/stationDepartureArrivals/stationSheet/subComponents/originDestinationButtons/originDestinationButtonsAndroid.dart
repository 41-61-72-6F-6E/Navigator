import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/station_sheet_notifier.dart';

class originDestinationButtonsAndroid extends StatelessWidget {
  final StationSheetNotifier notifier;
  final void Function(BuildContext context, Station station, bool value) onTapped;

  const originDestinationButtonsAndroid({
    super.key,
    required this.notifier,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(width: 16),
        Expanded(
          child: M3EFilledButton.tonal(
            shape: M3EButtonShape.square,
            size: M3EButtonSize.sm,
            semanticLabel: "Set as Origin",
            onPressed: () => onTapped(context, notifier.selectedStation!, true),
            child: Text("Use as Origin"),
          ),
        ),
        SizedBox(width: 8,),
        Expanded(
          child: M3EFilledButton.tonal(
            shape: M3EButtonShape.square,
            size: M3EButtonSize.sm,
            onPressed: () => onTapped(context, notifier.selectedStation!, false),
            child: Text("Use as Destination"),
          ),
        ),
        SizedBox(width: 16,)
      ],
    );
  }
}