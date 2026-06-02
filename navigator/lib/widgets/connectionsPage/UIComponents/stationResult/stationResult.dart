import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/stationResult/stationResultAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class StationResult extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final Station station;
  final bool searchingFrom;
  final void Function(Station, bool searchingFrom) onStationSelected;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const StationResult({
    super.key,
    required this.design,
    required this.model,
    required this.station,
    required this.searchingFrom,
    required this.onStationSelected,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return StationResultAndroid(
          model: model,
          station: station,
          searchingFrom: searchingFrom,
          onStationSelected: onStationSelected,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
      default:
        return StationResultAndroid(
          model: model,
          station: station,
          searchingFrom: searchingFrom,
          onStationSelected: onStationSelected,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
    }
  }
}