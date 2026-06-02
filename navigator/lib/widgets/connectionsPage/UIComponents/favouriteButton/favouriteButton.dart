import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/favouriteButton/favouriteButtonAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class FavouriteButton extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final Location location;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const FavouriteButton({
    super.key,
    required this.design,
    required this.model,
    required this.location,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return FavouriteButtonAndroid(
          model: model,
          location: location,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
      default:
        return FavouriteButtonAndroid(
          model: model,
          location: location,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
    }
  }
}