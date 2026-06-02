import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/modeLine/modeLine.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class JourneyCardAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final Journey journey;
  final void Function(Journey) onJourneyTap;

  const JourneyCardAndroid({
    super.key,
    required this.model,
    required this.journey,
    required this.onJourneyTap,
  });

  @override
  Widget build(BuildContext context) {
    final Journey j = journey;

    int shortestInterchangeInMinutes = 100;
    bool shouldShowShortInterchange = false;
    if (model.getShortestInterchange(j) != null) {
      shortestInterchangeInMinutes = model.getShortestInterchange(j)!;
      if (shortestInterchangeInMinutes <= 5) {
        shouldShowShortInterchange = true;
      }
    }

    String tripDuration = '';
    Duration tripD = j.legs.last.plannedArrivalDateTime
        .difference(j.legs.first.plannedDepartureDateTime);
    if (tripD.inMinutes < 60) {
      tripDuration = '${tripD.inMinutes} min';
    } else if (tripD.inHours < 24) {
      int minutes = tripD.inMinutes % 60;
      int hours = ((tripD.inMinutes - minutes) / 60).round();
      tripDuration = '${hours}h${minutes}m';
    } else {
      int minutes = tripD.inMinutes % 60;
      int hours = ((tripD.inMinutes - minutes) / 60).round() % 24;
      int days =
          (((tripD.inMinutes - (hours * 60)) - minutes) / 24).round();
      tripDuration = '${days}d${hours}h${minutes}m';
    }

    String plannedDepartureTimeHour =
        '${j.legs.first.plannedDepartureDateTime.toLocal().hour}'
            .padLeft(2, '0');
    String plannedDepartureTimeMinute =
        '${j.legs.first.plannedDepartureDateTime.toLocal().minute}'
            .padLeft(2, '0');
    String plannedArrivalTimeHour =
        '${j.legs.last.plannedArrivalDateTime.toLocal().hour}'
            .padLeft(2, '0');
    String plannedArrivalTimeMinute =
        '${j.legs.last.plannedArrivalDateTime.toLocal().minute}'
            .padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onJourneyTap(j),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      '$plannedDepartureTimeHour:$plannedDepartureTimeMinute'
                      ' to '
                      '$plannedArrivalTimeHour:$plannedArrivalTimeMinute',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(
                            color:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                    Spacer(),
                    Text(
                      tripDuration,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(
                            color:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                child: ModeLine(
                  design: 0,
                  model: model,
                  journey: j,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4),
                          child: Row(
                            spacing: 4,
                            children: [
                              Icon(
                                Icons.transfer_within_a_station,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                                size: 16,
                              ),
                              SizedBox(width: 24),
                              Text(
                                '${model.calculateTotalInterchanges(j)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (shouldShowShortInterchange)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              spacing: 4,
                              children: [
                                Icon(
                                  Icons.error,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                                Text(
                                  'short Transfer: $shortestInterchangeInMinutes min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}