import 'package:flutter/material.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/pages/android/connections_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/widgets/homePage/UIComponents/editFavoritesModal/editFavoritesModal.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class FavesBarAndroid extends StatelessWidget {
  final HomePageModel model;

  const FavesBarAndroid({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final state = model.state;
    return Row(
      children: [
        if (state.faves.isEmpty) const SizedBox(width: 16),
        if (state.faves.isEmpty)
          Text(
            'No saved Locations so far',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        if (state.faves.isEmpty) const Spacer(),
        if (state.faves.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: state.faves
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IntrinsicWidth(
                          child: ActionChip(
                            label: Text(
                              f.name,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: false).push(
                              MaterialPageRoute(
                                builder: (_) => ConnectionsPageAndroid(
                                  ConnectionsPage(
                                    from: Location(
                                        id: '',
                                        latitude: 0,
                                        longitude: 0,
                                        name: '',
                                        type: ''),
                                    to: f.location,
                                    services: model.page.service,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(width: 14),
        IconButton(
          onPressed: () => EditFavoritesModal.show(context, model),
          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
          tooltip: 'Edit Saved Locations',
        ),
      ],
    );
  }
}