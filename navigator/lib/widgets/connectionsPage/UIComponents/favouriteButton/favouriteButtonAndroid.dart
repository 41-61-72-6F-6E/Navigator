import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class FavouriteButtonAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final Location location;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const FavouriteButtonAndroid({
    super.key,
    required this.model,
    required this.location,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    bool alreadyFave = false;
    FavoriteLocation? thatFave;
    for (int i = 0; i < model.faves.length; i++) {
      if (model.faves[i].location.id == location.id) {
        alreadyFave = true;
        thatFave = model.faves[i];
      }
    }

    if (alreadyFave) {
      return IconButton(
        icon: Icon(Icons.favorite),
        onPressed: () => onRemoveFavourite(thatFave!),
      );
    }

    return IconButton(
      icon: Icon(Icons.favorite_border),
      onPressed: () => _showAddFavouriteDialog(context, location),
    );
  }

  void _showAddFavouriteDialog(BuildContext context, Location location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController c = TextEditingController();
        return AlertDialog(
          title: Text(
            'Save Location',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Give the location a name so you can better remember it',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              TextField(
                controller: c,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Localdatasaver.addLocationToFavourites(
                    location, c.text);
                onAddFavourite(location);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}