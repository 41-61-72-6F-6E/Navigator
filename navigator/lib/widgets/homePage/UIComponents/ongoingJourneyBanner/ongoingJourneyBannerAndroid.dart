import 'package:flutter/material.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/models/trip.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class OngoingJourneyBannerAndroid extends StatefulWidget {
  final HomePageModel model;

  const OngoingJourneyBannerAndroid({
    super.key,
    required this.model,
  });

  @override
  State<OngoingJourneyBannerAndroid> createState() =>
      _OngoingJourneyBannerAndroidState();
}

class _OngoingJourneyBannerAndroidState
    extends State<OngoingJourneyBannerAndroid> {
  @override
  Widget build(BuildContext context) {
    final state = widget.model.state;
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    int situationUpperBox = 0;
    int situationLowerBox = 0;
    int leg = 0;
    bool afterArrival = false;

    for (int i = 0; i < state.ongoingJourney!.journey.legs.length; i++) {
      final l = state.ongoingJourney!.journey.legs[i];
      if (DateTime.now().isAfter(l.plannedDepartureDateTime)) {
        afterArrival = false;
        leg = i;
      }
      if (DateTime.now().isAfter(l.plannedArrivalDateTime)) {
        afterArrival = true;
      }
    }

    final int currentLeg = leg;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.model.setOngoingJourneyCurrentLegIndex(currentLeg);
    });

    if (!afterArrival) {
      if (state.ongoingJourney!.journey.legs[leg].isWalking == true) {
        situationUpperBox = 2;
        situationLowerBox =
            leg == state.ongoingJourney!.journey.legs.length - 1 ? 3 : 0;
      } else {
        situationUpperBox = 1;
        situationLowerBox = 1;
      }
    } else {
      if (leg == state.ongoingJourney!.journey.legs.length - 1) {
        situationUpperBox = 0;
        situationLowerBox = 3;
      } else {
        situationUpperBox = 0;

        int nextActualLegIndex = leg + 1;
        while (nextActualLegIndex <
            state.ongoingJourney!.journey.legs.length) {
          final nextLeg =
              state.ongoingJourney!.journey.legs[nextActualLegIndex];
          bool isSameStationInterchange =
              nextLeg.origin.id == nextLeg.destination.id &&
                  nextLeg.origin.name == nextLeg.destination.name;
          if (!isSameStationInterchange) break;
          nextActualLegIndex++;
        }

        if (nextActualLegIndex <
            state.ongoingJourney!.journey.legs.length) {
          final currentLeg = state.ongoingJourney!.journey.legs[leg];
          final nextLeg =
              state.ongoingJourney!.journey.legs[nextActualLegIndex];

          bool isWalkingInterchange = false;

          if (nextActualLegIndex - leg > 1) {
            for (int interchangeIndex = leg + 1;
                interchangeIndex < nextActualLegIndex;
                interchangeIndex++) {
              final interchangeLeg =
                  state.ongoingJourney!.journey.legs[interchangeIndex];
              if (interchangeLeg.origin.id ==
                      interchangeLeg.destination.id &&
                  interchangeLeg.origin.name ==
                      interchangeLeg.destination.name) {
                isWalkingInterchange = true;
                break;
              }
            }
          }

          if (nextLeg.isWalking == true &&
              nextLeg.origin.ril100Ids.isNotEmpty &&
              nextLeg.destination.ril100Ids.isNotEmpty &&
              widget.model.haveSameRil100Station(nextLeg.origin.ril100Ids,
                  nextLeg.destination.ril100Ids)) {
            isWalkingInterchange = true;
          }

          if (currentLeg.destination.ril100Ids.isNotEmpty &&
              nextLeg.origin.ril100Ids.isNotEmpty &&
              widget.model.haveSameRil100Station(currentLeg.destination.ril100Ids,
                  nextLeg.origin.ril100Ids)) {
            isWalkingInterchange = true;
          }

          if (nextLeg.isWalking == true) {
            situationLowerBox = 2;
          } else {
            situationLowerBox = 0;
          }
        } else {
          situationLowerBox = 3;
        }
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        width: double.infinity,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 0,
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          color: colors.surfaceContainerLowest,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text('ongoing Journey',
                    style: texts.titleSmall!
                        .copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                OngoingJourneyUpperBoxAndroid(
                    model: widget.model, leg: leg, situation: situationUpperBox),
                const SizedBox(height: 8),
                OngoingJourneyLowerBoxAndroid(
                    model: widget.model, leg: leg, situation: situationLowerBox),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Upper Box ────────────────────────────────────────────────────────────

class OngoingJourneyUpperBoxAndroid extends StatelessWidget {
  final HomePageModel model;
  final int leg;
  final int situation;

  const OngoingJourneyUpperBoxAndroid({
    super.key,
    required this.model,
    required this.leg,
    required this.situation,
  });

  @override
  Widget build(BuildContext context) {
    final state = model.state;
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    switch (situation) {
      case 0:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.primary,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('at station',
                      style: texts.bodyMedium!
                          .copyWith(color: colors.onPrimary)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.ongoingJourney!.journey.legs[leg].destination.name,
                    style: texts.headlineMedium!
                        .copyWith(color: colors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        );

      case 1:
        Color lineColor = state.ongoingJourney!.journey.legs[leg]
                .lineColorNotifier.value ??
            Colors.grey;
        Color onLineColor =
            ThemeData.estimateBrightnessForColor(lineColor) == Brightness.dark
                ? Colors.white
                : Colors.black;

        Trip? t = state.legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival =
                state.ongoingJourney!.journey.legs[leg].arrivalDateTime;
            if (arrivalTime != null) {
              if (arrivalTime.isBefore(now)) {
                stopsBeforeCurrentPosition.add(s);
              } else if (arrivalTime.isBefore(legArrival)) {
                stopsBeforeInterchange.add(s);
              } else {
                stopsAfterInterchange.add(s);
              }
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.primary,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'on the ${state.ongoingJourney!.journey.legs[leg].product}',
                    style: texts.bodyMedium!
                        .copyWith(color: colors.onPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (state.ongoingJourney!.journey.legs[leg].lineName !=
                        null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: lineColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: Text(
                            state.ongoingJourney!.journey.legs[leg].lineName!,
                            style: texts.labelMedium!
                                .copyWith(color: onLineColor),
                          ),
                        ),
                      ),
                    if (state.ongoingJourney!.journey.legs[leg].direction !=
                        null)
                      const SizedBox(width: 8),
                    if (state.ongoingJourney!.journey.legs[leg].direction !=
                        null)
                      Text(
                        state.ongoingJourney!.journey.legs[leg].direction!,
                        style: texts.titleLarge!
                            .copyWith(color: colors.onPrimary),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (t == null)
                  Text('Loading trip details...',
                      style: texts.bodyMedium!
                          .copyWith(color: colors.onPrimary))
                else if (t.stopovers.isEmpty)
                  Text('No stops on this line',
                      style: texts.bodyMedium!
                          .copyWith(color: colors.onPrimary))
                else
                  IntermediateStopsExpanderAndroid(
                    model: model,
                    stopsBeforeInterchange: stopsBeforeInterchange,
                    stopsAfterInterchange: stopsAfterInterchange,
                  ),
              ],
            ),
          ),
        );

      case 2:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.primary,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Walk ${state.ongoingJourney!.journey.legs[leg].distance}m (${state.ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(state.ongoingJourney!.journey.legs[leg].departureDateTime).inMinutes} minutes) towards',
                    style: texts.bodyMedium!
                        .copyWith(color: colors.onPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.ongoingJourney!.journey.legs[leg].destination.name,
                    style: texts.titleLarge!
                        .copyWith(color: colors.onPrimary),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryContainer),
                  onPressed: () => model.focusMapOnLeg(
                      state.ongoingJourney!.journey.legs[leg]),
                  label: Text('Focus on Map',
                      style: texts.bodyMedium!
                          .copyWith(color: colors.onPrimaryContainer)),
                  icon: Icon(Icons.map_outlined,
                      color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Intermediate Stops Expander ─────────────────────────────────────────

class IntermediateStopsExpanderAndroid extends StatelessWidget {
  final HomePageModel model;
  final List<Stopover> stopsBeforeInterchange;
  final List<Stopover> stopsAfterInterchange;

  const IntermediateStopsExpanderAndroid({
    super.key,
    required this.model,
    required this.stopsBeforeInterchange,
    required this.stopsAfterInterchange,
  });

  @override
  Widget build(BuildContext context) {
    final state = model.state;
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: model.toggleIntermediateStops,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Row(
                children: [
                  Text('Show Intermediate Stops',
                      style: texts.titleMedium!
                          .copyWith(color: colors.onPrimaryContainer)),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
                      child: Row(
                        children: [
                          Text('${stopsBeforeInterchange.length}',
                              style: texts.labelMedium!
                                  .copyWith(color: colors.onPrimary)),
                          AnimatedRotation(
                            turns: state
                                    .ongoingJourneyIntermediateStopsExpanded
                                ? 0.5
                                : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: Icon(Icons.keyboard_arrow_down,
                                color: colors.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                height: state.ongoingJourneyIntermediateStopsExpanded
                    ? 300.0
                    : 0,
                child: state.ongoingJourneyIntermediateStopsExpanded
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 8.0, bottom: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...stopsBeforeInterchange.map((s) {
                              String timeText =
                                  model.generateStopoverTimeText(s);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor:
                                          colors.tertiaryContainer),
                                  onPressed: () {},
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(s.station.name,
                                            style: texts.titleMedium!
                                                .copyWith(
                                                    color: colors
                                                        .onTertiaryContainer)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(timeText,
                                                style: texts.titleMedium!
                                                    .copyWith(
                                                        color: colors
                                                            .onTertiaryContainer)),
                                            if (s.arrivalPlatform != null)
                                              Text(
                                                'Platform ${s.arrivalPlatform!}',
                                                style: texts.bodyMedium!
                                                    .copyWith(
                                                        color: colors
                                                            .onTertiaryContainer),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (stopsAfterInterchange.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: colors.tertiary),
                                  onPressed: () {},
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stopsAfterInterchange
                                              .first.station.name,
                                          style: texts.titleMedium!.copyWith(
                                              color: colors.onTertiary),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              model.generateStopoverTimeText(
                                                  stopsAfterInterchange
                                                      .first),
                                              style: texts.titleMedium!
                                                  .copyWith(
                                                      color:
                                                          colors.onTertiary),
                                            ),
                                            if (stopsAfterInterchange
                                                    .first.arrivalPlatform !=
                                                null)
                                              Text(
                                                'Platform ${stopsAfterInterchange.first.arrivalPlatform}',
                                                style: texts.bodyMedium!
                                                    .copyWith(
                                                        color: colors
                                                            .onTertiary),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ...stopsAfterInterchange.skip(1).map((s) {
                              String timeText =
                                  model.generateStopoverTimeText(s);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0),
                                child: OutlinedButton(
                                  onPressed: () {},
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(s.station.name,
                                            style: texts.titleMedium!
                                                .copyWith(
                                                    color: colors
                                                        .onPrimaryContainer)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(timeText,
                                                style: texts.titleMedium!
                                                    .copyWith(
                                                        color: colors
                                                            .onPrimaryContainer)),
                                            if (s.arrivalPlatform != null)
                                              Text(
                                                'Platform ${s.arrivalPlatform!}',
                                                style: texts.bodyMedium!
                                                    .copyWith(
                                                        color: colors
                                                            .onPrimaryContainer),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lower Box ────────────────────────────────────────────────────────────

class OngoingJourneyLowerBoxAndroid extends StatelessWidget {
  final HomePageModel model;
  final int leg;
  final int situation;

  const OngoingJourneyLowerBoxAndroid({
    super.key,
    required this.model,
    required this.leg,
    required this.situation,
  });

  @override
  Widget build(BuildContext context) {
    final state = model.state;
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    switch (situation) {
      case 0:
        Color lineColor = state.ongoingJourney!.journey.legs[leg + 1]
                .lineColorNotifier.value ??
            Colors.grey;
        Color onLineColor =
            ThemeData.estimateBrightnessForColor(lineColor) == Brightness.dark
                ? Colors.white
                : Colors.black;

        return Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: state.lowerBoxExpanded
                ? BorderRadius.circular(24)
                : const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take the ${state.ongoingJourney!.journey.legs[leg + 1].product}',
                            style: texts.bodyMedium!.copyWith(
                                color: colors.onPrimaryContainer),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (state.ongoingJourney!.journey
                                      .legs[leg + 1].lineName !=
                                  null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: lineColor,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    child: Text(
                                      state.ongoingJourney!.journey
                                          .legs[leg + 1].lineName!,
                                      style: texts.labelMedium!
                                          .copyWith(color: onLineColor),
                                    ),
                                  ),
                                ),
                              if (state.ongoingJourney!.journey
                                      .legs[leg + 1].direction !=
                                  null)
                                const SizedBox(width: 8),
                              if (state.ongoingJourney!.journey
                                      .legs[leg + 1].direction !=
                                  null)
                                Flexible(
                                  child: Text(
                                    state.ongoingJourney!.journey
                                        .legs[leg + 1].direction!,
                                    style: texts.titleLarge!.copyWith(
                                        color: colors.onPrimaryContainer),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              model.prettyPrintTime(state.ongoingJourney!
                                  .journey.legs[leg + 1].departureDateTime),
                              style: texts.titleMedium!.copyWith(
                                  color: colors.onTertiaryContainer),
                            ),
                            if (state.ongoingJourney!.journey
                                    .legs[leg + 1].arrivalPlatform !=
                                null)
                              Text(
                                'Platform ${state.ongoingJourney!.journey.legs[leg + 1].arrivalPlatform!}',
                                style: texts.bodyMedium!.copyWith(
                                    color: colors.onTertiaryContainer),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case 1:
        Trip? t = state.legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival =
                state.ongoingJourney!.journey.legs[leg].arrivalDateTime;
            if (arrivalTime != null) {
              if (arrivalTime.isBefore(now)) {
                stopsBeforeCurrentPosition.add(s);
              } else if (arrivalTime.isBefore(legArrival)) {
                stopsBeforeInterchange.add(s);
              } else {
                stopsAfterInterchange.add(s);
              }
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get off in ${state.ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(DateTime.now()).inMinutes} minutes(${stopsBeforeInterchange.length + 1} stops) at',
                          style: texts.bodyMedium!.copyWith(
                              color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.ongoingJourney!.journey.legs[leg].destination
                              .name,
                          style: texts.titleLarge!
                              .copyWith(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              model.prettyPrintTime(state.ongoingJourney!
                                  .journey.legs[leg].arrivalDateTime),
                              style: texts.titleMedium!.copyWith(
                                  color: colors.onTertiaryContainer),
                            ),
                            if (state.ongoingJourney!.journey.legs[leg]
                                    .arrivalPlatform !=
                                null)
                              Text(
                                'Platform ${state.ongoingJourney!.journey.legs[leg].arrivalPlatform!}',
                                style: texts.bodyMedium!.copyWith(
                                    color: colors.onTertiaryContainer),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case 2:
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            color: colors.primaryContainer,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Walk ${state.ongoingJourney!.journey.legs[leg + 1].distance}m (${state.ongoingJourney!.journey.legs[leg + 1].arrivalDateTime.difference(state.ongoingJourney!.journey.legs[leg + 1].departureDateTime).inMinutes} minutes) towards',
                    style: texts.bodyMedium!
                        .copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.ongoingJourney!.journey.legs[leg + 1].destination
                        .name,
                    style: texts.titleLarge!
                        .copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: colors.primary),
                  onPressed: () => model.focusMapOnLeg(
                      state.ongoingJourney!.journey.legs[leg + 1]),
                  label: Text('Focus on Map',
                      style: texts.bodyMedium!
                          .copyWith(color: colors.onPrimary)),
                  icon:
                      Icon(Icons.map_outlined, color: colors.onPrimary),
                ),
              ],
            ),
          ),
        );

      case 3:
        Trip? t = state.legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival =
                state.ongoingJourney!.journey.legs[leg].arrivalDateTime;
            if (arrivalTime != null) {
              if (arrivalTime.isBefore(now)) {
                stopsBeforeCurrentPosition.add(s);
              } else if (arrivalTime.isBefore(legArrival)) {
                stopsBeforeInterchange.add(s);
              } else {
                stopsAfterInterchange.add(s);
              }
            }
          }
        }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arrive in ${state.ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(DateTime.now()).inMinutes} minutes at',
                                style: texts.bodyMedium!.copyWith(
                                    color: colors.onPrimaryContainer),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.ongoingJourney!.journey.legs[leg]
                                    .destination.name,
                                style: texts.titleLarge!.copyWith(
                                    color: colors.onPrimaryContainer),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Column(
                              children: [
                                Text(
                                  model.prettyPrintTime(state
                                      .ongoingJourney!
                                      .journey
                                      .legs[leg]
                                      .arrivalDateTime),
                                  style: texts.titleMedium!.copyWith(
                                      color: colors.onTertiaryContainer),
                                ),
                                if (state.ongoingJourney!.journey.legs[leg]
                                        .arrivalPlatform !=
                                    null)
                                  Text(
                                    'Platform ${state.ongoingJourney!.journey.legs[leg].arrivalPlatform!}',
                                    style: texts.bodyMedium!.copyWith(
                                        color: colors.onTertiaryContainer),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}