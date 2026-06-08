import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/android/connections_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPage.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class StationResultCardAndroid extends StatelessWidget {
  final HomePageModel model;
  final Station station;

  const StationResultCardAndroid({
    super.key,
    required this.model,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context, rootNavigator: false).push(
          MaterialPageRoute(
            builder: (_) => ConnectionsPage(
              ConnectionsPageIni(
                from: Location(
                    id: '', latitude: 0, longitude: 0, name: '', type: ''),
                to: station,
                services: model.page.service,
              ),
            ),
          ),
        ),
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
                      colors.onTertiaryContainer, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (station.national || station.nationalExpress)
                          Icon(Icons.train, size: 20, color: colors.tertiary),
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
                          Icon(Icons.subway, size: 20, color: colors.tertiary),
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
              FavouriteButton(model: model, location: station),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationResultCardAndroid extends StatelessWidget {
  final HomePageModel model;
  final Location location;

  const LocationResultCardAndroid({
    super.key,
    required this.model,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context, rootNavigator: false).push(
          MaterialPageRoute(
            builder: (_) => ConnectionsPage(
              ConnectionsPageIni(
                from: Location(
                    id: '', latitude: 0, longitude: 0, name: '', type: ''),
                to: location,
                services: model.page.service,
              ),
            ),
          ),
        ),
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
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              FavouriteButton(model: model, location: location),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class FavouriteButton extends StatelessWidget {
  final HomePageModel model;
  final Location location;

  const FavouriteButton({
    super.key,
    required this.model,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model.faves,
      builder: (context, _) {
        bool alreadyFave = false;
        FavoriteLocation? thatFave;
        for (int i = 0; i < model.faves.faves.length; i++) {
          if (model.faves.faves[i].location.id == location.id) {
            alreadyFave = true;
            thatFave = model.faves.faves[i];
          }
        }

        if (alreadyFave) {
          return IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => model.removeFavourite(thatFave!),
          );
        }

        return IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () => showDialog(
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
                      style:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    TextField(
                      controller: c,
                      style:
                          Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await model.addFavourite(location, c.text);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}