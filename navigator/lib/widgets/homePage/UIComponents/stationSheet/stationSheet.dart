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

  @override
  static Future<T?> show<T>(BuildContext context, HomePageModel model, int design, Station station) {
    switch (design) {
      case 0:
        return showModalBottomSheet<T>(
          context: context,
          builder: (context) => StationSheetAndroid(model: model, station: station),
        );
      // Future designs can be added here
      default:
        return showModalBottomSheet<T>(
          context: context,
          builder: (context) => StationSheetAndroid(model: model, station: station),
        );
    }
  }
}

