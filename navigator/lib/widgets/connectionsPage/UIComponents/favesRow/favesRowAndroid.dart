import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class FavesRowAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final bool searchingFrom;
  final void Function(FavoriteLocation, bool searchingFrom) onFaveChipTap;

  const FavesRowAndroid({
    super.key,
    required this.model,
    required this.searchingFrom,
    required this.onFaveChipTap,
  });

  @override
  Widget build(BuildContext context) {
    final faves = model.faves;
    return Row(
      children: [
        if (faves.isEmpty) Icon(Icons.favorite),
        if (faves.isEmpty) SizedBox(width: 16),
        if (faves.isEmpty)
          Text(
            'No saved Locations so far',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        if (faves.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: faves
                    .map(
                      (f) => Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: IntrinsicWidth(
                          child: ActionChip(
                            label: Text(
                              f.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                            ),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer,
                            onPressed: () => onFaveChipTap(f, searchingFrom),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}