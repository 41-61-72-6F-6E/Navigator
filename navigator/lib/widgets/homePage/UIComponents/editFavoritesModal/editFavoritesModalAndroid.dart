import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class EditFavoritesModalAndroid {
  static void show(BuildContext context, HomePageModel model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 400),
      ),
      builder: (BuildContext context) {
        return ListenableBuilder(
          listenable: model.faves,
          builder: (context, _) {
            final colors = Theme.of(context).colorScheme;
            final texts = Theme.of(context).textTheme;
            final faves = model.faves.faves;

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colors.onSurfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: colors.primary, size: 28),
                              const SizedBox(width: 16),
                              Text(
                                'Edit Saved Locations',
                                style: texts.headlineSmall!.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (faves.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${faves.length}',
                                    style: texts.bodySmall!.copyWith(
                                        color: colors.onSecondaryContainer,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: faves.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.favorite_outline,
                                          size: 64,
                                          color: colors.onSurfaceVariant
                                              .withOpacity(0.5)),
                                      const SizedBox(height: 16),
                                      Text('No saved locations yet',
                                          style: texts.titleMedium!.copyWith(
                                              color: colors.onSurfaceVariant)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add locations to favorites to manage them here. \n'
                                        'Do this by searching for a station or location and tapping the heart icon.',
                                        style: texts.bodyMedium!.copyWith(
                                            color: colors.onSurfaceVariant
                                                .withOpacity(0.7)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ReorderableListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 24),
                                  itemCount: faves.length,
                                  onReorder: (oldIndex, newIndex) async {
                                    if (newIndex > oldIndex) newIndex -= 1;
                                    List<FavoriteLocation> reorderedFaves =
                                        List.from(faves);
                                    final item =
                                        reorderedFaves.removeAt(oldIndex);
                                    reorderedFaves.insert(newIndex, item);
                                    await model
                                        .saveFavoriteOrder(reorderedFaves);
                                    await model.reloadFaves();
                                  },
                                  itemBuilder: (context, index) {
                                    final fave = faves[index];
                                    return Padding(
                                      key: ValueKey(
                                          '${fave.location.id}_$index'),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                colors.primaryContainer,
                                            child: Icon(
                                              fave.location is Station
                                                  ? Icons.train
                                                  : Icons.location_on,
                                              color: colors.onPrimaryContainer,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            fave.name,
                                            style: texts.titleMedium!.copyWith(
                                                color: colors.onSurface,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                            fave.location.name,
                                            style: texts.bodySmall!.copyWith(
                                                color: colors.onSurfaceVariant),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit_outlined,
                                                    color: colors.primary,
                                                    size: 20),
                                                onPressed: () =>
                                                    _showRenameFavoriteDialog(
                                                        context, model, fave),
                                                tooltip: 'Rename',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                    Icons.delete_outline,
                                                    color: colors.error,
                                                    size: 20),
                                                onPressed: () =>
                                                    _showDeleteFavoriteDialog(
                                                        context, model, fave),
                                                tooltip: 'Remove',
                                              ),
                                              ReorderableDragStartListener(
                                                index: index,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: colors.outline
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                      Icons.drag_handle,
                                                      color: colors
                                                          .onSurfaceVariant,
                                                      size: 20),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static void _showRenameFavoriteDialog(
    BuildContext context,
    HomePageModel model,
    FavoriteLocation fave,
  ) {
    final TextEditingController controller =
        TextEditingController(text: fave.name);
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Rename Location',
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: colors.onSurface),
          ),
          content: TextField(
            controller: controller,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: colors.onSurface),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Location Name',
              hintText: 'Enter new name',
              hintStyle: TextStyle(color: colors.onSurfaceVariant),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await Localdatasaver.removeFavouriteLocation(fave);
                  await Localdatasaver.addLocationToFavourites(
                      fave.location, controller.text.trim());
                  await model.reloadFaves();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  static void _showDeleteFavoriteDialog(
    BuildContext context,
    HomePageModel model,
    FavoriteLocation fave,
  ) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Remove Location',
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: colors.onSurface),
          ),
          content: Text(
            'Are you sure you want to remove "${fave.name}" from your saved locations?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError),
              onPressed: () async {
                await model.removeFavourite(fave);
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}