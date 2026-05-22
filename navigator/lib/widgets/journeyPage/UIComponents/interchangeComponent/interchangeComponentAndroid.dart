import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';

class InterchangeComponentAndroid extends StatelessWidget {
  final Leg arrivingLeg;
  final Leg departingLeg;
  final String? platformChangeText;
  final bool showInterchangeTime;

  const InterchangeComponentAndroid({
    super.key,
    required this.arrivingLeg,
    required this.departingLeg,
    required this.platformChangeText,
    required this.showInterchangeTime,
  });

  @override
  Widget build(BuildContext context) {
    Color arrivalTimeColor = Theme.of(context).colorScheme.onSurface;
    Color departureTimeColor = Theme.of(context).colorScheme.onPrimaryContainer;
    Color arrivalPlatformColor = Theme.of(context).colorScheme.onSurface;
    Color departurePlatformColor = Theme.of(context).colorScheme.onPrimaryContainer;

    if (arrivingLeg.arrivalDelayMinutes != null) {
      if (arrivingLeg.arrivalDelayMinutes! > 10) {
        arrivalTimeColor = Theme.of(context).colorScheme.error;
      } else if (arrivingLeg.arrivalDelayMinutes! > 0) {
        arrivalTimeColor = Theme.of(context).colorScheme.tertiary;
      }
    }

    if (departingLeg.departureDelayMinutes != null) {
      if (departingLeg.departureDelayMinutes! > 10) {
        departureTimeColor = Theme.of(context).colorScheme.error;
      } else if (departingLeg.departureDelayMinutes! > 0) {
        departureTimeColor = Theme.of(context).colorScheme.tertiary;
      }
    }

    if (arrivingLeg.arrivalPlatform != arrivingLeg.arrivalPlatformEffective) {
      arrivalPlatformColor = Theme.of(context).colorScheme.error;
    }
    if (departingLeg.departurePlatform != departingLeg.departurePlatformEffective) {
      departurePlatformColor = Theme.of(context).colorScheme.error;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    double height = 220;
    int upperFlex = 60;
    if (!showInterchangeTime) {
      height -= 20;
      upperFlex += 8;
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Column(
            children: [
              Flexible(
                flex: upperFlex,
                child: Container(
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        color: colorScheme.surfaceContainerLowest,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withAlpha(20),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Arrival ${arrivingLeg.effectiveArrivalFormatted}',
                              style: textTheme.titleMedium!.copyWith(color: arrivalTimeColor),
                            ),
                            if (arrivingLeg.arrivalPlatform == null)
                              Text(
                                'at the Station',
                                style: textTheme.bodySmall!.copyWith(color: colorScheme.onSurface),
                              ),
                            if (arrivingLeg.arrivalPlatform != null)
                              Text(
                                'Platform ${arrivingLeg.effectiveArrivalPlatform}',
                                style: textTheme.bodySmall!.copyWith(color: arrivalPlatformColor),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 120,
                child: Container(
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    color: colorScheme.surfaceContainerLowest,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                departingLeg.origin.name,
                                style: textTheme.headlineMedium?.copyWith(
                                    color: colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (departingLeg.departureDateTime
                                          .difference(arrivingLeg.arrivalDateTime)
                                          .inMinutes <
                                      4 &&
                                  showInterchangeTime)
                                Text(
                                  'Interchange Time: ${departingLeg.departureDateTime.difference(arrivingLeg.arrivalDateTime).inMinutes} min',
                                  style: textTheme.titleSmall!
                                      .copyWith(color: colorScheme.error),
                                ),
                              if (departingLeg.departureDateTime
                                          .difference(arrivingLeg.arrivalDateTime)
                                          .inMinutes >=
                                      4 &&
                                  showInterchangeTime)
                                Text(
                                  'Interchange Time: ${departingLeg.departureDateTime.difference(arrivingLeg.arrivalDateTime).inMinutes} min',
                                  style: textTheme.titleSmall!
                                      .copyWith(color: colorScheme.onSurface),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 60,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 16,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                                    color: colorScheme.primaryContainer,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow
                                            .withAlpha(20),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Departure ${departingLeg.effectiveDepartureFormatted}',
                                          style: textTheme.titleMedium!
                                              .copyWith(color: departureTimeColor),
                                        ),
                                        if (departingLeg.departurePlatform == null)
                                          Text(
                                            'at the Station',
                                            style: textTheme.bodyMedium!.copyWith(
                                                color: colorScheme.onPrimaryContainer),
                                          ),
                                        if (departingLeg.departurePlatform != null)
                                          Text(
                                            'Platform ${departingLeg.effectiveDeparturePlatform}',
                                            style: textTheme.bodyMedium!
                                                .copyWith(color: departurePlatformColor),
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}