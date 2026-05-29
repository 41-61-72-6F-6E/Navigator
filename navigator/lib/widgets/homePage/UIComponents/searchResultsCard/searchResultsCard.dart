import 'package:flutter/material.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/UIComponents/searchResultsCard/searchResultsCardAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class StationResultCard extends StatelessWidget {
  final int design;
  final HomePageModel model;
  final Station station;

  const StationResultCard({
    super.key,
    required this.design,
    required this.model,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return StationResultCardAndroid(model: model, station: station);
      // Future designs can be added here
      default:
        return StationResultCardAndroid(model: model, station: station);
    }
  }
}

class LocationResultCard extends StatelessWidget {
  final int design;
  final HomePageModel model;
  final Location location;

  const LocationResultCard({
    super.key,
    required this.design,
    required this.model,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return LocationResultCardAndroid(model: model, location: location);
      // Future designs can be added here
      default:
        return LocationResultCardAndroid(model: model, location: location);
    }
  }
}