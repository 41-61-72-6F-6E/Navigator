import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/searchResults/searchResultsAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class SearchResults extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final bool searchingFrom;
  final void Function(Station, bool searchingFrom) onStationSelected;
  final void Function(Location, bool searchingFrom) onLocationSelected;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const SearchResults({
    super.key,
    required this.design,
    required this.model,
    required this.searchingFrom,
    required this.onStationSelected,
    required this.onLocationSelected,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return SearchResultsAndroid(
          model: model,
          searchingFrom: searchingFrom,
          onStationSelected: onStationSelected,
          onLocationSelected: onLocationSelected,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
      default:
        return SearchResultsAndroid(
          model: model,
          searchingFrom: searchingFrom,
          onStationSelected: onStationSelected,
          onLocationSelected: onLocationSelected,
          onAddFavourite: onAddFavourite,
          onRemoveFavourite: onRemoveFavourite,
        );
    }
  }
}