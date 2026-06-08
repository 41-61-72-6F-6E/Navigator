import 'package:flutter/material.dart';
import 'package:navigator/widgets/customWidgets/parent_child_checkboxes.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class MapOptionsModalAndroid {
  static void show(BuildContext context, HomePageModel model) {
    showModalBottomSheet(
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 400),
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Initialise from the notifier once when the modal opens.
            // setModalState keeps the modal's own checkboxes in sync instantly
            // while model.updateMapOptions updates the map behind it.
            bool localShowLightRail = model.layers.showLightRail;
            bool localShowStationLabelsLightRail =
                model.layers.showStationLabelsLightRail;
            bool localShowSubway = model.layers.showSubway;
            bool localShowStationLabelsSubway =
                model.layers.showStationLabelsSubway;
            bool localShowTram = model.layers.showTram;
            bool localShowStationLabelsTram =
                model.layers.showStationLabelsTram;
            bool localShowFerry = model.layers.showFerry;
            bool localShowStationLabelsFerry =
                model.layers.showStationLabelsFerry;
            bool localShowFunicular = model.layers.showFunicular;
            bool localShowStationLabelsFunicular =
                model.layers.showStationLabelsFunicular;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Map Options',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            activeColor:
                                Theme.of(context).colorScheme.primary,
                            parentLabel: 'S-Bahn',
                            initialParentValue: localShowLightRail &&
                                localShowStationLabelsLightRail,
                            childrenLabels: [
                              'Lines(S-Bahn)',
                              'Station Labels(S-Bahn)'
                            ],
                            initialChildrenValues: [
                              localShowLightRail,
                              localShowStationLabelsLightRail,
                            ],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowLightRail = p1[0];
                                localShowStationLabelsLightRail = p1[1];
                              });
                              model.updateMapOptions(
                                showLightRail: p1[0],
                                showStationLabelsLightRail: p1[1],
                              );
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            activeColor:
                                Theme.of(context).colorScheme.primary,
                            parentLabel: 'U-Bahn',
                            initialParentValue: localShowSubway &&
                                localShowStationLabelsSubway,
                            childrenLabels: [
                              'Lines(U-Bahn)',
                              'Station Labels(U-Bahn)'
                            ],
                            initialChildrenValues: [
                              localShowSubway,
                              localShowStationLabelsSubway,
                            ],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowSubway = p1[0];
                                localShowStationLabelsSubway = p1[1];
                              });
                              model.updateMapOptions(
                                showSubway: p1[0],
                                showStationLabelsSubway: p1[1],
                              );
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            activeColor:
                                Theme.of(context).colorScheme.primary,
                            parentLabel: 'Tram',
                            initialParentValue:
                                localShowTram && localShowStationLabelsTram,
                            childrenLabels: [
                              'Lines(Tram)',
                              'Station Labels(Tram)'
                            ],
                            initialChildrenValues: [
                              localShowTram,
                              localShowStationLabelsTram,
                            ],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowTram = p1[0];
                                localShowStationLabelsTram = p1[1];
                              });
                              model.updateMapOptions(
                                showTram: p1[0],
                                showStationLabelsTram: p1[1],
                              );
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            activeColor:
                                Theme.of(context).colorScheme.primary,
                            parentLabel: 'Ferry',
                            initialParentValue: localShowFerry &&
                                localShowStationLabelsFerry,
                            childrenLabels: [
                              'Lines(Ferry)',
                              'Station Labels(Ferry)'
                            ],
                            initialChildrenValues: [
                              localShowFerry,
                              localShowStationLabelsFerry,
                            ],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowFerry = p1[0];
                                localShowStationLabelsFerry = p1[1];
                              });
                              model.updateMapOptions(
                                showFerry: p1[0],
                                showStationLabelsFerry: p1[1],
                              );
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            activeColor:
                                Theme.of(context).colorScheme.primary,
                            parentLabel: 'Funicular',
                            initialParentValue: localShowFunicular &&
                                localShowStationLabelsFunicular,
                            childrenLabels: [
                              'Lines(Funicular)',
                              'Station Labels(Funicular)'
                            ],
                            initialChildrenValues: [
                              localShowFunicular,
                              localShowStationLabelsFunicular,
                            ],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowFunicular = p1[0];
                                localShowStationLabelsFunicular = p1[1];
                              });
                              model.updateMapOptions(
                                showFunicular: p1[0],
                                showStationLabelsFunicular: p1[1],
                              );
                            },
                          ),
                        ],
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
  }
}