import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationSheet/subComponents/originDestinationButtons/originDestinationButtonsAndroid.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/station_sheet_notifier.dart';

class originDestinationButtons extends StatelessWidget {
  final int design;
  final void Function(BuildContext context, Station station, bool value) onTapped;
  final StationSheetNotifier notifier;

  const originDestinationButtons({
    super.key,
    required this.design,
    required this.onTapped,
    required this.notifier
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return originDestinationButtonsAndroid(notifier: notifier, onTapped: onTapped);
      default:
        return originDestinationButtonsAndroid(notifier: notifier, onTapped: onTapped);
    }
  }
}