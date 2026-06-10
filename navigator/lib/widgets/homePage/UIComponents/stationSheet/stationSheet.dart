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
  static Future<T?> show<T>(
    BuildContext context,
    HomePageModel model,
    int design,
    Station station,
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
              listenable: model.layers,
              builder: (context, child) => StationSheetAndroid(
                model: model,
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
              listenable: model.layers,
              builder: (context, child) => StationSheetAndroid(
                model: model,
                station: station,
                scrollController: scrollController, // pass it down
              ),
            ),
          ),
        );
  
}
  }}
