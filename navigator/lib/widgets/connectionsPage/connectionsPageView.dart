import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/journeySettings.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';


/// Pure view layer.  Receives everything it needs via constructor parameters
/// and callbacks – it never reads or mutates state directly.
class ConnectionsPageView {
  // ── Constructor ───────────────────────────────────────────────────────────

  const ConnectionsPageView({
    required this.model,
    required this.uiState,
    required this.fromController,
    required this.toController,
    required this.fromFocusNode,
    required this.toFocusNode,
    required this.scrollController,
    required this.onFromLocationTap,
    required this.onToLocationTap,
    required this.onSwitch,
    required this.onStationSelected,
    required this.onLocationSelected,
    required this.onSearch,
    required this.onAddEarlier,
    required this.onAddLater,
    required this.onJourneyTap,
    required this.onTimeChanged,
    required this.onDateChanged,
    required this.onDepartureChanged,
    required this.onSettingsChanged,
    required this.onFaveChipTap,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
    required this.onResetToNow,
  });

  // ── Injected state (read-only references) ─────────────────────────────────
  final ConnectionsPageModel model;
  final ConnectionsPageUIState uiState;

  // ── Controllers / nodes ───────────────────────────────────────────────────
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocusNode;
  final FocusNode toFocusNode;
  final ScrollController? scrollController;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  final VoidCallback onFromLocationTap;
  final VoidCallback onToLocationTap;
  final VoidCallback onSwitch;
  final void Function(Station, bool searchingFrom) onStationSelected;
  final void Function(Location, bool searchingFrom) onLocationSelected;
  final VoidCallback onSearch;
  final VoidCallback onAddEarlier;
  final VoidCallback onAddLater;
  final void Function(Journey) onJourneyTap;
  final void Function(TimeOfDay) onTimeChanged;
  final void Function(DateTime) onDateChanged;
  final void Function(bool) onDepartureChanged;
  final void Function(JourneySettings) onSettingsChanged;
  final void Function(FavoriteLocation, bool searchingFrom) onFaveChipTap;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;
  final VoidCallback onResetToNow;

  // ═══════════════════════════════════════════════════════════════════════════
  // Public build entry-points
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildInputFields(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(width: 1, color: colors.outline),
        color: colors.secondaryContainer,
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: TextField(
                    controller: fromController,
                    focusNode: fromFocusNode,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      fillColor: colors.surface,
                      filled: true,
                      labelText: 'From',
                      labelStyle: TextStyle(color: colors.onSurface),
                      prefixIcon: GestureDetector(
                        onTap: onFromLocationTap,
                        child: Icon(Icons.location_on, color: colors.onSurface),
                      ),
                      border: OutlineInputBorder().copyWith(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: TextField(
                    controller: toController,
                    focusNode: toFocusNode,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      fillColor: colors.surface,
                      filled: true,
                      labelText: 'To',
                      labelStyle: TextStyle(color: colors.onSurface),
                      prefixIcon: GestureDetector(
                        onTap: onToLocationTap,
                        child: Icon(Icons.location_on, color: colors.onSurface),
                      ),
                      border: OutlineInputBorder().copyWith(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedRotation(
                  turns: uiState.rotateSwitchButton ? 0.5 : 0.0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.primary,
                      iconSize: 32,
                      side: BorderSide(color: colors.outline, width: 1),
                    ),
                    onPressed: onSwitch,
                    icon: Icon(Icons.swap_vert),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFaves(BuildContext context, bool searchingFrom) {
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
                            onPressed: () =>
                                onFaveChipTap(f, searchingFrom),
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

  Widget buildSearchResults(BuildContext context, bool searchingFrom) {
    final results = searchingFrom
        ? model.searchResultsFrom
        : model.searchResultsTo;

    if (results.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final r = results[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: r is Station
              ? _stationResult(context, r)
              : _locationResult(context, r),
        );
      },
    );
  }

  Widget buildJourneys(BuildContext context) {
    if (model.currentJourneys == null) {
      return Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (model.currentJourneys!.isEmpty) {
      return Expanded(child: Center(child: Text('No journeys found')));
    }

    if (uiState.shouldAutoScrollToTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController?.hasClients == true) {
          scrollController!.animateTo(
            48,
            duration: Duration(milliseconds: 700),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Expanded(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onResetToNow,
                  child: Text('Now'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAddEarlier,
                    child: Text('Earlier'),
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  _buildJourneyCard(context, model.currentJourneys![i]),
              childCount: model.currentJourneys!.length,
            ),
          ),
          SliverToBoxAdapter(
            child: OutlinedButton(
              onPressed: onAddLater,
              child: Text('Later'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.departure_board),
                label: Text(model.selectedTime.format(context)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: model.selectedTime,
                    helpText: 'Select Departure or Arrival Time',
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          timePickerTheme: TimePickerThemeData(
                            helpTextStyle: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) onTimeChanged(time);
                },
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.calendar_month),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: model.selectedDate,
                    helpText: 'Select Departure Or Arrival Date',
                  );
                  if (date != null) onDateChanged(date);
                },
                label: Text(
                  '${model.selectedDate.day}.${model.selectedDate.month}.${model.selectedDate.year}',
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _showSettingsDialog(context, colors),
              icon: Icon(Icons.settings),
              tooltip: 'Journey Settings',
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(value: true, label: Text('Departure')),
                  ButtonSegment<bool>(value: false, label: Text('Arrival')),
                ],
                selected: {model.departure},
                onSelectionChanged: (Set<bool> newSelection) =>
                    onDepartureChanged(newSelection.first),
              ),
            ),
            GestureDetector(
              onTap: onSearch,
              child: AnimatedContainer(
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      uiState.inJourneySearchAnimation ? 8 : 24),
                  color: uiState.inJourneySearchAnimation
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedRotation(
                        curve: Curves.easeInOut,
                        turns: uiState.rotatingSearchIconTurns,
                        duration: Duration(milliseconds: 600),
                        child: Icon(
                          Icons.search,
                          color: uiState.inJourneySearchAnimation
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Search',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(
                              color: uiState.inJourneySearchAnimation
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildFavouriteButton(BuildContext context, Location location) {
    bool alreadyFave = false;
    FavoriteLocation? thatFave;
    for (int i = 0; i < model.faves.length; i++) {
      if (model.faves[i].location.id == location.id) {
        alreadyFave = true;
        thatFave = model.faves[i];
      }
    }

    if (alreadyFave) {
      return IconButton(
        icon: Icon(Icons.favorite),
        onPressed: () => onRemoveFavourite(thatFave!),
      );
    }

    return IconButton(
      icon: Icon(Icons.favorite_border),
      onPressed: () => _showAddFavouriteDialog(context, location),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _stationResult(BuildContext context, Station station) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainerHighest,
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        child: InkWell(
          onTap: () =>
              onStationSelected(station, uiState.searchingFrom),
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
                            Icon(Icons.tram,
                                size: 20, color: colors.tertiary),
                          if (station.taxi)
                            Icon(Icons.local_taxi,
                                size: 20, color: colors.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
                buildFavouriteButton(context, station),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationResult(BuildContext context, Location location) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainerHighest,
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () =>
            onLocationSelected(location, uiState.searchingFrom),
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
              buildFavouriteButton(context, location),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, Journey j) {
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
                padding:
                    EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                    ),
                    Spacer(),
                    Text(
                      tripDuration,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    EdgeInsetsGeometry.symmetric(vertical: 8),
                child: _buildModeLine(context, j),
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

  Widget _buildModeLine(BuildContext context, Journey j) {
    int totalTripDuration = j.legs.last.plannedArrivalDateTime
        .difference(j.legs.first.plannedDepartureDateTime)
        .inSeconds;
    List<String> legNames = [];
    List<double> legPercentages = [];
    List<String> legLineNames = [];

    List<int> actualLegIndices = [];

    for (int index = 0; index < j.legs.length; index++) {
      final leg = j.legs[index];
      bool isSameStationInterchange =
          leg.origin.id == leg.destination.id &&
          leg.origin.name == leg.destination.name;
      bool isWalkingWithinStationComplex = leg.isWalking == true &&
          leg.origin.ril100Ids.isNotEmpty &&
          leg.destination.ril100Ids.isNotEmpty &&
          model.haveSameRil100ID(
              leg.origin.ril100Ids, leg.destination.ril100Ids);
      if (!isSameStationInterchange && !isWalkingWithinStationComplex) {
        actualLegIndices.add(index);
      }
    }

    for (int i = 0; i < actualLegIndices.length; i++) {
      int legIndex = actualLegIndices[i];
      Leg l = j.legs[legIndex];

      if ((l.product == null || l.product!.isEmpty) &&
          l.productName == null) {
        int legDuration = l.plannedArrivalDateTime
            .difference(l.plannedDepartureDateTime)
            .inSeconds;
        double percentage = (legDuration / totalTripDuration) * 100;
        if (model.haveSameRil100ID(
            l.origin.ril100Ids, l.destination.ril100Ids)) {
          legNames.add('transfer');
          legLineNames.add('');
        } else {
          legNames.add('walk');
          legLineNames.add('');
        }
        legPercentages.add(percentage);
      } else {
        int legDuration = l.plannedArrivalDateTime
            .difference(l.plannedDepartureDateTime)
            .inSeconds;
        double percentage = (legDuration / totalTripDuration) * 100;
        if (l.product == null && l.productName != null) {
          legNames.add(l.productName!.toLowerCase());
        } else {
          legNames.add(l.product!);
        }
        legLineNames.add(l.lineName!);
        legPercentages.add(percentage);
      }

      if (i < actualLegIndices.length - 1) {
        int nextLegIndex = actualLegIndices[i + 1];
        Leg nextLeg = j.legs[nextLegIndex];

        bool shouldShowTransfer = false;

        if (nextLegIndex - legIndex > 1) {
          for (int interchangeIndex = legIndex + 1;
              interchangeIndex < nextLegIndex;
              interchangeIndex++) {
            final interchangeLeg = j.legs[interchangeIndex];
            if (interchangeLeg.origin.id ==
                    interchangeLeg.destination.id &&
                interchangeLeg.origin.name ==
                    interchangeLeg.destination.name) {
              shouldShowTransfer = true;
              break;
            }
          }
        } else if (l.destination.id == nextLeg.origin.id &&
            l.destination.name == nextLeg.origin.name &&
            ((l.isWalking == true && nextLeg.isWalking != true) ||
                (l.isWalking != true && nextLeg.isWalking == true) ||
                (l.isWalking != true &&
                    nextLeg.isWalking != true &&
                    l.lineName != nextLeg.lineName))) {
          shouldShowTransfer = true;
        }

        bool isWithinStationComplex =
            l.destination.ril100Ids.isNotEmpty &&
            nextLeg.origin.ril100Ids.isNotEmpty &&
            model.haveSameRil100ID(
                l.destination.ril100Ids, nextLeg.origin.ril100Ids);

        if (isWithinStationComplex || shouldShowTransfer) {
          int transferTime = nextLeg.plannedDepartureDateTime
              .difference(l.plannedArrivalDateTime)
              .inSeconds;
          if (transferTime > 0) {
            double transferPercentage =
                (transferTime / totalTripDuration) * 100;
            legNames.add('transfer');
            legLineNames.add('');
            legPercentages.add(transferPercentage);
          }
        }
      }
    }

    for (int i = 0; i < legNames.length; i++) {
      print(legNames[i] + legPercentages[i].toString());
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: List.generate(legNames.length, (index) {
              double segmentWidth =
                  constraints.maxWidth * (legPercentages[index] / 100);
              Icon icon = Icon(Icons.directions_walk);
              bool light =
                  Theme.of(context).brightness == Brightness.light;
              Color color = Colors.grey;
              Color onColor = light ? Colors.white : Colors.black;
              bool showText = true;
              String text = legLineNames[index];

              const double minWidthForIcon = 24.0;
              const double minWidthForText = 60.0;

              bool shouldShowIcon = segmentWidth >= minWidthForIcon;
              bool shouldShowTextContent =
                  segmentWidth >= minWidthForText && showText;

              switch (legNames[index]) {
                case 'transfer':
                  icon = Icon(Icons.transfer_within_a_station);
                  showText = false;
                  break;
                case 'walk':
                  icon = Icon(Icons.directions_walk);
                  showText = false;
                  break;
                case 'bus':
                  icon = Icon(Icons.directions_bus);
                  color = light
                      ? Colors.deepPurple
                      : Colors.purpleAccent;
                  break;
                case 'nationalExpress':
                  icon = Icon(Icons.train);
                  color = light ? Colors.black : Colors.white;
                  break;
                case 'national':
                  icon = Icon(Icons.train);
                  color = light
                      ? Colors.teal.shade900
                      : Colors.teal.shade300;
                  break;
                case 'regional':
                  icon = Icon(Icons.directions_railway);
                  color = light
                      ? Colors.yellow.shade900
                      : Colors.yellow.shade300;
                  break;
                case 'regionalExpress':
                  icon = Icon(Icons.directions_railway);
                  color = light
                      ? Colors.pink.shade900
                      : Colors.pink.shade300;
                  break;
                case 'suburban':
                  icon = Icon(Icons.directions_subway);
                  color = light
                      ? Colors.green.shade900
                      : Colors.green.shade300;
                  break;
                case 'subway':
                  icon = Icon(Icons.subway_outlined);
                  color = light
                      ? Colors.blue.shade900
                      : Colors.blue.shade300;
                  break;
                case 'tram':
                  icon = Icon(Icons.tram);
                  color = light
                      ? Colors.deepOrange.shade900
                      : Colors.deepOrange.shade300;
                  break;
                case 'taxi':
                  icon = Icon(Icons.local_taxi);
                  color = light
                      ? Colors.amber.shade300
                      : Colors.amber.shade700;
                  break;
                case 'ferry':
                  icon = Icon(Icons.directions_boat);
                  color = light
                      ? Colors.cyan.shade300
                      : Colors.cyan.shade800;
                  break;
                default:
                  icon = Icon(Icons.directions_walk);
                  showText = false;
              }

              return Flexible(
                flex: math.max(legPercentages[index].round(), 1),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(color: color),
                  child: shouldShowIcon
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 4),
                            child: shouldShowTextContent
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(icon.icon,
                                          color: onColor, size: 16),
                                      Flexible(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(
                                                  left: 4.0),
                                          child: Text(
                                            text,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: onColor,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Icon(icon.icon,
                                    color: onColor, size: 16),
                          ),
                        )
                      : Container(),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddFavouriteDialog(BuildContext context, Location location) {
    showDialog(
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              TextField(
                controller: c,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Localdatasaver.addLocationToFavourites(
                    location, c.text);
                onAddFavourite(location);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(
      BuildContext context, ColorScheme colors) async {
    JourneySettings tempSettings = JourneySettings(
      national: model.journeySettings.national,
      nationalExpress: model.journeySettings.nationalExpress,
      regional: model.journeySettings.regional,
      regionalExpress: model.journeySettings.regionalExpress,
      suburban: model.journeySettings.suburban,
      subway: model.journeySettings.subway,
      tram: model.journeySettings.tram,
      bus: model.journeySettings.bus,
      ferry: model.journeySettings.ferry,
      deutschlandTicketConnectionsOnly:
          model.journeySettings.deutschlandTicketConnectionsOnly,
      accessibility: model.journeySettings.accessibility,
      walkingSpeed: model.journeySettings.walkingSpeed,
      transferTime: model.journeySettings.transferTime,
    );

    final updatedSettings = await showDialog<JourneySettings>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Journey Preferences',
            style: TextStyle(color: colors.onSurface),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Modes of Transport',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      title: Text('Include ICE',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.national ?? true,
                      onChanged: (value) => setState(
                          () => tempSettings.national = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include IC/EC',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.nationalExpress ?? true,
                      onChanged: (value) => setState(
                          () => tempSettings.nationalExpress = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include RE/RB',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.regional ?? true,
                      onChanged: (value) => setState(() {
                        tempSettings.regional = value;
                        tempSettings.regionalExpress = value;
                      }),
                    ),
                    CheckboxListTile(
                      title: Text('Include S-Bahn',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.suburban ?? true,
                      onChanged: (value) => setState(
                          () => tempSettings.suburban = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include U-Bahn',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.subway ?? true,
                      onChanged: (value) => setState(
                          () => tempSettings.subway = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include Tram',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.tram ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.tram = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include Bus',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.bus ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.bus = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include Ferry',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.ferry ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.ferry = value),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Journey Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      title: Text('Deutschlandticket only',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings
                              .deutschlandTicketConnectionsOnly ??
                          false,
                      onChanged: (value) => setState(() =>
                          tempSettings
                              .deutschlandTicketConnectionsOnly =
                          value),
                    ),
                    CheckboxListTile(
                      title: Text('Accessibility',
                          style:
                              TextStyle(color: colors.onSurface)),
                      value: tempSettings.accessibility ?? false,
                      onChanged: (value) => setState(
                          () => tempSettings.accessibility = value),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Walking Speed',
                              style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child:
                                  DropdownButtonFormField<String>(
                                value: tempSettings.walkingSpeed ??
                                    'normal',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10),
                                ),
                                style: TextStyle(
                                    color: colors.onSurface),
                                iconEnabledColor: colors.primary,
                                items: [
                                  DropdownMenuItem(
                                      value: 'slow',
                                      child: Text('Slow')),
                                  DropdownMenuItem(
                                      value: 'normal',
                                      child: Text('Normal')),
                                  DropdownMenuItem(
                                      value: 'fast',
                                      child: Text('Fast')),
                                ],
                                onChanged: (value) => setState(
                                    () => tempSettings
                                        .walkingSpeed = value),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Transfer Time',
                              style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child:
                                  DropdownButtonFormField<int?>(
                                value: tempSettings.transferTime,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10),
                                ),
                                style: TextStyle(
                                    color: colors.onSurface),
                                iconEnabledColor: colors.primary,
                                items: [
                                  DropdownMenuItem(
                                      value: null,
                                      child:
                                          Text('Default (None)')),
                                  DropdownMenuItem(
                                      value: 5,
                                      child:
                                          Text('Min. 5 Minutes')),
                                  DropdownMenuItem(
                                      value: 15,
                                      child:
                                          Text('Min. 15 Minutes')),
                                  DropdownMenuItem(
                                      value: 30,
                                      child:
                                          Text('Min. 30 Minutes')),
                                ],
                                onChanged: (value) => setState(
                                    () => tempSettings
                                        .transferTime = value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(tempSettings),
              child: Text('Apply'),
            ),
          ],
        );
      },
    );

    if (updatedSettings != null) onSettingsChanged(updatedSettings);
  }
}