import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/locationResult/locationResultAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class LocationResult extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final Location location;
  final bool searchingFrom;
  final void Function(Location, bool searchingFrom) onLocationSelected;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const LocationResult({
    super.key,
    required this.design,
    required this.model,
    required this.location,
    required this.searchingFrom,
    required this.onLocationSelected,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return LocationResultAndroid(
          model: model,
          location: location,
          searchingFrom: searchingFrom,
          onLocationSelected: onLocationSelected,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
      default:
        return LocationResultAndroid(
          model: model,
          location: location,
          searchingFrom: searchingFrom,
          onLocationSelected: onLocationSelected,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
    }
  }
}