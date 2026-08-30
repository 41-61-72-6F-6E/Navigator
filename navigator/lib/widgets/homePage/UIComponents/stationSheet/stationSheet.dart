import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/stationSheetAndroid.dart';

class StationSheet {
  final int design;
  final HomePageModel model;
  final Station station;

  const StationSheet({
    required this.design,
    required this.model,
    required this.station,
  });

  static Future<T?> show<T>(
    BuildContext context,
    HomePageModel model,
    int design,
    Station station,
  ) {
    switch (design) {
      case 0:
        return showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.82,
            child: StationSheetAndroid(model: model, station: station),
          ),
        );
      // Future designs can be added here
      default:
        return showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.82,
            child: StationSheetAndroid(model: model, station: station),
          ),
        );
    }
  }
}
