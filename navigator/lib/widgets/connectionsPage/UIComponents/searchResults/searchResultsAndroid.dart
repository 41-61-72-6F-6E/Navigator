import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/locationResult/locationResult.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/stationResult/stationResult.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class SearchResultsAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final bool searchingFrom;
  final void Function(Station, bool searchingFrom) onStationSelected;
  final void Function(Location, bool searchingFrom) onLocationSelected;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const SearchResultsAndroid({
    super.key,
    required this.model,
    required this.searchingFrom,
    required this.onStationSelected,
    required this.onLocationSelected,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final results =
        searchingFrom ? model.searchResultsFrom : model.searchResultsTo;

    if (results.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final r = results[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: r is Station
              ? StationResult(
                  design: 0,
                  model: model,
                  station: r,
                  searchingFrom: searchingFrom,
                  onStationSelected: onStationSelected,
                  onAddFavourite: onAddFavourite,
                  onRemoveFavourite: onRemoveFavourite,
                )
              : LocationResult(
                  design: 0,
                  model: model,
                  location: r,
                  searchingFrom: searchingFrom,
                  onLocationSelected: onLocationSelected,
                  onAddFavourite: onAddFavourite,
                  onRemoveFavourite: onRemoveFavourite,
                ),
        );
      },
    );
  }
}