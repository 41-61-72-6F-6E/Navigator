import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/favouriteButton/favouriteButton.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class StationResultAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final Station station;
  final bool searchingFrom;
  final void Function(Station, bool searchingFrom) onStationSelected;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;

  const StationResultAndroid({
    super.key,
    required this.model,
    required this.station,
    required this.searchingFrom,
    required this.onStationSelected,
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
      child: GestureDetector(
        child: InkWell(
          onTap: () => onStationSelected(station, searchingFrom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.tertiaryContainer,
                  child: SvgPicture.asset(
                    "assets/Icon/Train_Station_Icon.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colors.onTertiaryContainer,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (station.national || station.nationalExpress)
                            Icon(Icons.train,
                                size: 20, color: colors.tertiary),
                          if (station.regionalExpress)
                            Icon(Icons.directions_railway,
                                size: 20, color: colors.tertiary),
                          if (station.regional)
                            Icon(Icons.directions_transit,
                                size: 20, color: colors.tertiary),
                          if (station.suburban)
                            Icon(Icons.directions_subway,
                                size: 20, color: colors.tertiary),
                          if (station.bus)
                            Icon(Icons.directions_bus,
                                size: 20, color: colors.tertiary),
                          if (station.ferry)
                            Icon(Icons.directions_ferry,
                                size: 20, color: colors.tertiary),
                          if (station.subway)
                            Icon(Icons.subway,
                                size: 20, color: colors.tertiary),
                          if (station.tram)
                            Icon(Icons.tram, size: 20, color: colors.tertiary),
                          if (station.taxi)
                            Icon(Icons.local_taxi,
                                size: 20, color: colors.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
                FavouriteButton(
                  design: 0,
                  model: model,
                  location: station,
                  onAddFavourite: onAddFavourite,
                  onRemoveFavourite: onRemoveFavourite,
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}