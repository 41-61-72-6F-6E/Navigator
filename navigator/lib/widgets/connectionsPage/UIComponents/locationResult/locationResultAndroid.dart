import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/favouriteButton/favouriteButton.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class LocationResultAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final Location location;
  final bool searchingFrom;
  final void Function(Location, bool searchingFrom) onLocationSelected;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const LocationResultAndroid({
    super.key,
    required this.model,
    required this.location,
    required this.searchingFrom,
    required this.onLocationSelected,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainerHighest,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onLocationSelected(location, searchingFrom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.tertiaryContainer,
                child: Icon(Icons.house,
                    size: 24, color: colors.onTertiaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  location.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              FavouriteButton(
                design: 0,
                model: model,
                location: location,
                onAddFavourite: onAddFavourite,
                onRemoveFavourite: onRemoveFavourite,
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}