import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/models/trip.dart';
import 'package:navigator/pages/android/connections_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/customWidgets/parent_child_checkboxes.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class HomePageView extends StatefulWidget {
  final HomePageModel model;

  const HomePageView({super.key, required this.model});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);

    // Kick off init that needs vsync (animatedMapMove)
    widget.model.initiateLines();
    widget.model.fetchStations();
    widget.model.setInitialUserLocation(this);
    widget.model.initializeOngoingJourney();
    widget.model.getFaves();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.model.updateBrightness(
      Theme.of(context).colorScheme.brightness == Brightness.dark,
    );
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  // ─── Marker Layer ────────────────────────────────────────────────────────

  MarkerLayer? _createMarkerLayer(String transportType) {
    final state = widget.model.state;
    if (!widget.model.getShowLabels(transportType) || state.currentZoom <= 12) {
      return null;
    }
    ColorScheme colors = Theme.of(context).colorScheme;

    return MarkerLayer(
      markers: state.stations
          .where((station) {
            if (!widget.model.shouldShowStation(station, transportType)) return false;
            final minZoom = widget.model.getMinZoomForStation(station);
            if (state.currentZoom < minZoom) return false;
            return true;
          })
          .fold<Map<String, Station>>({}, (map, station) {
            if (state.currentZoom <= 15.5 && !map.containsKey(station.name)) {
              map[station.name] = station;
            } else if (state.currentZoom > 15.5) {
              map["${station.name}_${station.latitude}_${station.longitude}"] = station;
            }
            return map;
          })
          .values
          .fold<Map<String, List<Station>>>({}, (collisionMap, station) {
            if (state.currentZoom > 16.5) {
              final uniqueKey = "${station.name}_${station.latitude}_${station.longitude}";
              collisionMap[uniqueKey] = [station];
            } else {
              final key = widget.model.getLabelCollisionKey(station, state.currentZoom);
              if (!collisionMap.containsKey(key)) collisionMap[key] = [];
              collisionMap[key]!.add(station);
            }
            return collisionMap;
          })
          .entries
          .expand((entry) {
            final stations = entry.value;
            if (stations.length > 1 && state.currentZoom <= 17) {
              final uniqueByName = <String, Station>{};
              for (final s in stations) uniqueByName[s.name] = s;
              return uniqueByName.values;
            }
            return stations;
          })
          .map((station) {
            return Marker(
              point: LatLng(station.latitude, station.longitude),
              width: 150,
              height: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.currentZoom > 15.5)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        station.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (state.currentZoom > 14.5) const SizedBox(height: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(state.currentZoom > 14 ? 4 : 3),
                    child: Icon(
                      widget.model.getTransportIcon(station),
                      color: colors.onPrimary,
                      size: state.currentZoom > 14 ? 14 : 12,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  List<MarkerLayer> _buildMarkerLayers() {
    final state = widget.model.state;
    final layers = <MarkerLayer>[];
    if (state.showLightRail) {
      final layer = _createMarkerLayer('lightRail');
      if (layer != null) layers.add(layer);
    }
    if (state.showSubway) {
      final layer = _createMarkerLayer('subway');
      if (layer != null) layers.add(layer);
    }
    if (state.showTram) {
      final layer = _createMarkerLayer('tram');
      if (layer != null) layers.add(layer);
    }
    if (state.showFerry) {
      final layer = _createMarkerLayer('ferry');
      if (layer != null) layers.add(layer);
    }
    if (state.showFunicular) {
      final layer = _createMarkerLayer('funicular');
      if (layer != null) layers.add(layer);
    }
    return layers;
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = widget.model.state;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasResults = state.searchResults.isNotEmpty;
    const bottomSheetHeight = 96.0;

    return WillPopScope(
      onWillPop: () async {
        if (hasResults) {
          widget.model.clearSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(anim);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              child: hasResults
                  ? SafeArea(
                      child: ListView.builder(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, bottomSheetHeight + 16),
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, i) {
                          final r = state.searchResults[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: r is Station
                                ? _stationResult(context, r)
                                : _locationResult(context, r),
                          );
                        },
                      ),
                    )
                  : FlutterMap(
                      mapController: widget.model.mapController,
                      options: MapOptions(
                        initialCenter: state.currentUserLocation ?? state.currentCenter,
                        initialZoom: state.currentZoom,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.drag |
                              InteractiveFlag.flingAnimation |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom |
                              InteractiveFlag.rotate,
                          rotationThreshold: 20.0,
                          pinchZoomThreshold: 0.5,
                          pinchMoveThreshold: 40.0,
                        ),
                        onPositionChanged: widget.model.onPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (state.showSubway) PolylineLayer(polylines: state.subwayLines),
                        if (state.showLightRail) PolylineLayer(polylines: state.lightRailLines),
                        if (state.showTram) PolylineLayer(polylines: state.tramLines),
                        if (state.showFerry) PolylineLayer(polylines: state.ferryLines),
                        if (state.showFunicular) PolylineLayer(polylines: state.funicularLines),
                        if (state.ongoingJourney != null && state.ongoingJourneyPolylines.isNotEmpty)
                          PolylineLayer(polylines: state.ongoingJourneyPolylines),
                        CurrentLocationLayer(
                          alignPositionStream: widget.model.alignPositionStreamController.stream,
                          alignPositionOnUpdate: state.alignPositionOnUpdate,
                          style: LocationMarkerStyle(
                            marker: DefaultLocationMarker(color: Colors.lightBlue[800]!),
                            markerSize: const Size(20, 20),
                            markerDirection: MarkerDirection.heading,
                            accuracyCircleColor: Colors.blue[200]!.withAlpha(0x20),
                            headingSectorColor: Colors.blue[400]!.withAlpha(0x90),
                            headingSectorRadius: 60,
                          ),
                        ),
                        ..._buildMarkerLayers(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20.0, bottom: 160.0),
                            child: FloatingActionButton(
                              shape: const CircleBorder(),
                              onPressed: widget.model.recenterMap,
                              child: Icon(
                                Icons.my_location,
                                color: colors.tertiary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (state.ongoingJourney != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildOngoingJourney(context),
              ),
          ],
        ),
        bottomSheet: Material(
          color: colors.surfaceContainer,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.model.searchController,
                        onChanged: (v) {},
                        style: TextStyle(color: colors.onPrimaryContainer),
                        decoration: InputDecoration(
                          hintText: 'Where do you want to go?',
                          prefixIcon: Icon(Icons.location_pin, color: colors.primary),
                          filled: true,
                          fillColor: colors.primaryContainer,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      onPressed: () => _showMapOptionsModal(context),
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFaves(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Ongoing Journey ─────────────────────────────────────────────────────

  Widget _buildOngoingJourney(BuildContext context) {
    final state = widget.model.state;
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme texts = Theme.of(context).textTheme;
    int situationUpperBox = 0;
    int situationLowerBox = 0;
    bool isWalkingInterchange = false;

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

    widget.model.setOngoingJourneyCurrentLegIndex(leg);

    if (!afterArrival) {
      if (state.ongoingJourney!.journey.legs[leg].isWalking == true) {
        situationUpperBox = 2;
        situationLowerBox = leg == state.ongoingJourney!.journey.legs.length - 1 ? 3 : 0;
      } else {
        situationUpperBox = 1;
        situationLowerBox = 1;
      }
      isWalkingInterchange = false;
    } else {
      if (leg == state.ongoingJourney!.journey.legs.length - 1) {
        situationUpperBox = 0;
        situationLowerBox = 3;
        isWalkingInterchange = false;
      } else {
        situationUpperBox = 0;

        int nextActualLegIndex = leg + 1;
        while (nextActualLegIndex < state.ongoingJourney!.journey.legs.length) {
          final nextLeg = state.ongoingJourney!.journey.legs[nextActualLegIndex];
          bool isSameStationInterchange =
              nextLeg.origin.id == nextLeg.destination.id &&
              nextLeg.origin.name == nextLeg.destination.name;
          if (!isSameStationInterchange) break;
          nextActualLegIndex++;
        }

        if (nextActualLegIndex < state.ongoingJourney!.journey.legs.length) {
          final currentLeg = state.ongoingJourney!.journey.legs[leg];
          final nextLeg = state.ongoingJourney!.journey.legs[nextActualLegIndex];

          isWalkingInterchange = false;

          if (nextActualLegIndex - leg > 1) {
            for (int interchangeIndex = leg + 1;
                interchangeIndex < nextActualLegIndex;
                interchangeIndex++) {
              final interchangeLeg = state.ongoingJourney!.journey.legs[interchangeIndex];
              if (interchangeLeg.origin.id == interchangeLeg.destination.id &&
                  interchangeLeg.origin.name == interchangeLeg.destination.name) {
                isWalkingInterchange = true;
                break;
              }
            }
          }

          if (nextLeg.isWalking == true &&
              nextLeg.origin.ril100Ids.isNotEmpty &&
              nextLeg.destination.ril100Ids.isNotEmpty &&
              widget.model.haveSameRil100Station(
                  nextLeg.origin.ril100Ids, nextLeg.destination.ril100Ids)) {
            isWalkingInterchange = true;
          }

          if (currentLeg.destination.ril100Ids.isNotEmpty &&
              nextLeg.origin.ril100Ids.isNotEmpty &&
              widget.model.haveSameRil100Station(
                  currentLeg.destination.ril100Ids, nextLeg.origin.ril100Ids)) {
            isWalkingInterchange = true;
          }

          if (nextLeg.isWalking == true) {
            situationLowerBox = 2;
          } else {
            situationLowerBox = 0;
          }
        } else {
          situationLowerBox = 3;
          isWalkingInterchange = false;
        }
      }
    }

    Widget upperBox = Container();
    Widget lowerBox = Container();

    switch (situationUpperBox) {
      case 0:
        upperBox = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.primary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('at station',
                      style: texts.bodyMedium!.copyWith(color: colors.onPrimary)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.ongoingJourney!.journey.legs[leg].destination.name,
                    style: texts.headlineMedium!.copyWith(color: colors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 1:
        Color lineColor =
            state.ongoingJourney!.journey.legs[leg].lineColorNotifier.value ?? Colors.grey;
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
            DateTime legArrival = state.ongoingJourney!.journey.legs[leg].arrivalDateTime;
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

        upperBox = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.primary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'on the ${state.ongoingJourney!.journey.legs[leg].product}',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (state.ongoingJourney!.journey.legs[leg].lineName != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: lineColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Text(
                            state.ongoingJourney!.journey.legs[leg].lineName!,
                            style: texts.labelMedium!.copyWith(color: onLineColor),
                          ),
                        ),
                      ),
                    if (state.ongoingJourney!.journey.legs[leg].direction != null)
                      const SizedBox(width: 8),
                    if (state.ongoingJourney!.journey.legs[leg].direction != null)
                      Text(
                        state.ongoingJourney!.journey.legs[leg].direction!,
                        style: texts.titleLarge!.copyWith(color: colors.onPrimary),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (t == null)
                  Text('Loading trip details...',
                      style: texts.bodyMedium!.copyWith(color: colors.onPrimary))
                else if (t.stopovers.isEmpty)
                  Text('No stops on this line',
                      style: texts.bodyMedium!.copyWith(color: colors.onPrimary))
                else
                  GestureDetector(
                    onTap: widget.model.toggleIntermediateStops,
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
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
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
                                          turns: state.ongoingJourneyIntermediateStopsExpanded
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
                              height: state.ongoingJourneyIntermediateStopsExpanded ? 300.0 : 0,
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
                                                widget.model.generateStopoverTimeText(s);
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(vertical: 4.0),
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                    backgroundColor: colors.tertiaryContainer),
                                                onPressed: () {},
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(s.station.name,
                                                          style: texts.titleMedium!.copyWith(
                                                              color:
                                                                  colors.onTertiaryContainer)),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 4.0, horizontal: 8),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                        children: [
                                                          Text(timeText,
                                                              style: texts.titleMedium!.copyWith(
                                                                  color: colors
                                                                      .onTertiaryContainer)),
                                                          if (s.arrivalPlatform != null)
                                                            Text(
                                                              'Platform ${s.arrivalPlatform!}',
                                                              style: texts.bodyMedium!.copyWith(
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
                                          }).toList(),
                                          if (stopsAfterInterchange.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(vertical: 4.0),
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
                                                        stopsAfterInterchange.first.station.name,
                                                        style: texts.titleMedium!
                                                            .copyWith(color: colors.onTertiary),
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
                                                            widget.model.generateStopoverTimeText(
                                                                stopsAfterInterchange.first),
                                                            style: texts.titleMedium!
                                                                .copyWith(
                                                                    color: colors.onTertiary),
                                                          ),
                                                          if (stopsAfterInterchange
                                                                  .first.arrivalPlatform !=
                                                              null)
                                                            Text(
                                                              'Platform ${stopsAfterInterchange.first.arrivalPlatform}',
                                                              style: texts.bodyMedium!.copyWith(
                                                                  color: colors.onTertiary),
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
                                                widget.model.generateStopoverTimeText(s);
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(vertical: 4.0),
                                              child: OutlinedButton(
                                                onPressed: () {},
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(s.station.name,
                                                          style: texts.titleMedium!.copyWith(
                                                              color: colors.onPrimaryContainer)),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 4.0, horizontal: 8),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                        children: [
                                                          Text(timeText,
                                                              style: texts.titleMedium!.copyWith(
                                                                  color:
                                                                      colors.onPrimaryContainer)),
                                                          if (s.arrivalPlatform != null)
                                                            Text(
                                                              'Platform ${s.arrivalPlatform!}',
                                                              style: texts.bodyMedium!.copyWith(
                                                                  color:
                                                                      colors.onPrimaryContainer),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        break;
      case 2:
        upperBox = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.primary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Walk ${state.ongoingJourney!.journey.legs[leg].distance}m (${state.ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(state.ongoingJourney!.journey.legs[leg].departureDateTime).inMinutes} minutes) towards',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.ongoingJourney!.journey.legs[leg].destination.name,
                    style: texts.titleLarge!.copyWith(color: colors.onPrimary),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: colors.primaryContainer),
                  onPressed: () =>
                      widget.model.focusMapOnLeg(state.ongoingJourney!.journey.legs[leg]),
                  label: Text('Focus on Map',
                      style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer)),
                  icon: Icon(Icons.map_outlined, color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        );
    }

    switch (situationLowerBox) {
      case 0:
        Color lineColor =
            state.ongoingJourney!.journey.legs[leg + 1].lineColorNotifier.value ?? Colors.grey;
        Color onLineColor =
            ThemeData.estimateBrightnessForColor(lineColor) == Brightness.dark
                ? Colors.white
                : Colors.black;

        lowerBox = Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: state.lowerBoxExpanded
                ? BorderRadius.circular(24)
                : const BorderRadius.only(
                    topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                            style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (state.ongoingJourney!.journey.legs[leg + 1].lineName != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: lineColor,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    child: Text(
                                      state.ongoingJourney!.journey.legs[leg + 1].lineName!,
                                      style: texts.labelMedium!.copyWith(color: onLineColor),
                                    ),
                                  ),
                                ),
                              if (state.ongoingJourney!.journey.legs[leg + 1].direction != null)
                                const SizedBox(width: 8),
                              if (state.ongoingJourney!.journey.legs[leg + 1].direction != null)
                                Flexible(
                                  child: Text(
                                    state.ongoingJourney!.journey.legs[leg + 1].direction!,
                                    style: texts.titleLarge!
                                        .copyWith(color: colors.onPrimaryContainer),
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
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              widget.model.prettyPrintTime(state.ongoingJourney!.journey
                                  .legs[leg + 1].departureDateTime),
                              style:
                                  texts.titleMedium!.copyWith(color: colors.onTertiaryContainer),
                            ),
                            if (state.ongoingJourney!.journey.legs[leg + 1].arrivalPlatform !=
                                null)
                              Text(
                                'Platform ${state.ongoingJourney!.journey.legs[leg + 1].arrivalPlatform!}',
                                style: texts.bodyMedium!
                                    .copyWith(color: colors.onTertiaryContainer),
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
        break;
      case 1:
        Trip? t = state.legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival = state.ongoingJourney!.journey.legs[leg].arrivalDateTime;
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

        lowerBox = Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                          style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.ongoingJourney!.journey.legs[leg].destination.name,
                          style: texts.titleLarge!.copyWith(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              widget.model.prettyPrintTime(
                                  state.ongoingJourney!.journey.legs[leg].arrivalDateTime),
                              style: texts.titleMedium!
                                  .copyWith(color: colors.onTertiaryContainer),
                            ),
                            if (state.ongoingJourney!.journey.legs[leg].arrivalPlatform != null)
                              Text(
                                'Platform ${state.ongoingJourney!.journey.legs[leg].arrivalPlatform!}',
                                style: texts.bodyMedium!
                                    .copyWith(color: colors.onTertiaryContainer),
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
        break;
      case 2:
        lowerBox = Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            color: colors.primaryContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Walk ${state.ongoingJourney!.journey.legs[leg + 1].distance}m (${state.ongoingJourney!.journey.legs[leg + 1].arrivalDateTime.difference(state.ongoingJourney!.journey.legs[leg + 1].departureDateTime).inMinutes} minutes) towards',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.ongoingJourney!.journey.legs[leg + 1].destination.name,
                    style: texts.titleLarge!.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: colors.primary),
                  onPressed: () => widget.model
                      .focusMapOnLeg(state.ongoingJourney!.journey.legs[leg + 1]),
                  label: Text('Focus on Map',
                      style: texts.bodyMedium!.copyWith(color: colors.onPrimary)),
                  icon: Icon(Icons.map_outlined, color: colors.onPrimary),
                ),
              ],
            ),
          ),
        );
        break;
      case 3:
        Trip? t = state.legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival = state.ongoingJourney!.journey.legs[leg].arrivalDateTime;
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

        lowerBox = Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                style: texts.bodyMedium!
                                    .copyWith(color: colors.onPrimaryContainer),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.ongoingJourney!.journey.legs[leg].destination.name,
                                style: texts.titleLarge!
                                    .copyWith(color: colors.onPrimaryContainer),
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
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Column(
                              children: [
                                Text(
                                  widget.model.prettyPrintTime(state
                                      .ongoingJourney!.journey.legs[leg].arrivalDateTime),
                                  style: texts.titleMedium!
                                      .copyWith(color: colors.onTertiaryContainer),
                                ),
                                if (state.ongoingJourney!.journey.legs[leg].arrivalPlatform !=
                                    null)
                                  Text(
                                    'Platform ${state.ongoingJourney!.journey.legs[leg].arrivalPlatform!}',
                                    style: texts.bodyMedium!
                                        .copyWith(color: colors.onTertiaryContainer),
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
                    style: texts.titleSmall!.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                upperBox,
                const SizedBox(height: 8),
                lowerBox,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Map Options Modal ───────────────────────────────────────────────────

  void _showMapOptionsModal(BuildContext context) {
    final state = widget.model.state;
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
            // Local mirror so the modal UI can update instantly
            bool localShowLightRail = widget.model.state.showLightRail;
            bool localShowStationLabelsLightRail = widget.model.state.showStationLabelsLightRail;
            bool localShowSubway = widget.model.state.showSubway;
            bool localShowStationLabelsSubway = widget.model.state.showStationLabelsSubway;
            bool localShowTram = widget.model.state.showTram;
            bool localShowStationLabelsTram = widget.model.state.showStationLabelsTram;
            bool localShowFerry = widget.model.state.showFerry;
            bool localShowStationLabelsFerry = widget.model.state.showStationLabelsFerry;
            bool localShowFunicular = widget.model.state.showFunicular;
            bool localShowStationLabelsFunicular = widget.model.state.showStationLabelsFunicular;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Map Options',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
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
                            textColor: Theme.of(context).colorScheme.onSurface,
                            activeColor: Theme.of(context).colorScheme.primary,
                            parentLabel: 'S-Bahn',
                            initialParentValue: localShowLightRail && localShowStationLabelsLightRail,
                            childrenLabels: ['Lines(S-Bahn)', 'Station Labels(S-Bahn)'],
                            initialChildrenValues: [localShowLightRail, localShowStationLabelsLightRail],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowLightRail = p1[0];
                                localShowStationLabelsLightRail = p1[1];
                              });
                              widget.model.updateMapOptions(
                                  showLightRail: p1[0], showStationLabelsLightRail: p1[1]);
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor: Theme.of(context).colorScheme.onSurface,
                            activeColor: Theme.of(context).colorScheme.primary,
                            parentLabel: 'U-Bahn',
                            initialParentValue: localShowSubway && localShowStationLabelsSubway,
                            childrenLabels: ['Lines(U-Bahn)', 'Station Labels(U-Bahn)'],
                            initialChildrenValues: [localShowSubway, localShowStationLabelsSubway],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowSubway = p1[0];
                                localShowStationLabelsSubway = p1[1];
                              });
                              widget.model.updateMapOptions(
                                  showSubway: p1[0], showStationLabelsSubway: p1[1]);
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor: Theme.of(context).colorScheme.onSurface,
                            activeColor: Theme.of(context).colorScheme.primary,
                            parentLabel: 'Tram',
                            initialParentValue: localShowTram && localShowStationLabelsTram,
                            childrenLabels: ['Lines(Tram)', 'Station Labels(Tram)'],
                            initialChildrenValues: [localShowTram, localShowStationLabelsTram],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowTram = p1[0];
                                localShowStationLabelsTram = p1[1];
                              });
                              widget.model.updateMapOptions(
                                  showTram: p1[0], showStationLabelsTram: p1[1]);
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor: Theme.of(context).colorScheme.onSurface,
                            activeColor: Theme.of(context).colorScheme.primary,
                            parentLabel: 'Ferry',
                            initialParentValue: localShowFerry && localShowStationLabelsFerry,
                            childrenLabels: ['Lines(Ferry)', 'Station Labels(Ferry)'],
                            initialChildrenValues: [localShowFerry, localShowStationLabelsFerry],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowFerry = p1[0];
                                localShowStationLabelsFerry = p1[1];
                              });
                              widget.model.updateMapOptions(
                                  showFerry: p1[0], showStationLabelsFerry: p1[1]);
                            },
                          ),
                          const Divider(),
                          ParentChildCheckboxes(
                            textColor: Theme.of(context).colorScheme.onSurface,
                            activeColor: Theme.of(context).colorScheme.primary,
                            parentLabel: 'Funicular',
                            initialParentValue: localShowFunicular && localShowStationLabelsFunicular,
                            childrenLabels: ['Lines(Funicular)', 'Station Labels(Funicular)'],
                            initialChildrenValues: [localShowFunicular, localShowStationLabelsFunicular],
                            onSelectionChanged: (p0, p1) {
                              setModalState(() {
                                localShowFunicular = p1[0];
                                localShowStationLabelsFunicular = p1[1];
                              });
                              widget.model.updateMapOptions(
                                  showFunicular: p1[0], showStationLabelsFunicular: p1[1]);
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

  // ─── Faves ───────────────────────────────────────────────────────────────

  Widget _buildFaves(BuildContext context) {
    final state = widget.model.state;
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
                            onPressed: () => Navigator.of(context, rootNavigator: false).push(
                              MaterialPageRoute(
                                builder: (_) => ConnectionsPageAndroid(
                                  ConnectionsPage(
                                    from: Location(
                                        id: '', latitude: 0, longitude: 0, name: '', type: ''),
                                    to: f.location,
                                    services: widget.model.page.service,
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
          onPressed: () => _showEditFavoritesModal(context),
          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
          tooltip: 'Edit Saved Locations',
        ),
      ],
    );
  }

  // ─── Search Results ──────────────────────────────────────────────────────

  Widget _stationResult(BuildContext context, Station station) {
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
            builder: (_) => ConnectionsPageAndroid(
              ConnectionsPage(
                from: Location(id: '', latitude: 0, longitude: 0, name: '', type: ''),
                to: station,
                services: widget.model.page.service,
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
                  colorFilter: ColorFilter.mode(colors.onTertiaryContainer, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name,
                        style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (station.national || station.nationalExpress)
                          Icon(Icons.train, size: 20, color: colors.tertiary),
                        if (station.regionalExpress)
                          Icon(Icons.directions_railway, size: 20, color: colors.tertiary),
                        if (station.regional)
                          Icon(Icons.directions_transit, size: 20, color: colors.tertiary),
                        if (station.suburban)
                          Icon(Icons.directions_subway, size: 20, color: colors.tertiary),
                        if (station.bus)
                          Icon(Icons.directions_bus, size: 20, color: colors.tertiary),
                        if (station.ferry)
                          Icon(Icons.directions_ferry, size: 20, color: colors.tertiary),
                        if (station.subway)
                          Icon(Icons.subway, size: 20, color: colors.tertiary),
                        if (station.tram)
                          Icon(Icons.tram, size: 20, color: colors.tertiary),
                        if (station.taxi)
                          Icon(Icons.local_taxi, size: 20, color: colors.tertiary),
                      ],
                    ),
                  ],
                ),
              ),
              _buildFavouriteButton(context, station),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
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
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context, rootNavigator: false).push(
          MaterialPageRoute(
            builder: (_) => ConnectionsPageAndroid(
              ConnectionsPage(
                from: Location(id: '', latitude: 0, longitude: 0, name: '', type: ''),
                to: location,
                services: widget.model.page.service,
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
                child: Icon(Icons.house, size: 24, color: colors.onTertiaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(location.name,
                    style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant)),
              ),
              _buildFavouriteButton(context, location),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavouriteButton(BuildContext context, Location location) {
    final state = widget.model.state;
    bool alreadyFave = false;
    FavoriteLocation? thatFave;
    for (int i = 0; i < state.faves.length; i++) {
      if (state.faves[i].location.id == location.id) {
        alreadyFave = true;
        thatFave = state.faves[i];
      }
    }

    if (alreadyFave) {
      return IconButton(
        icon: const Icon(Icons.favorite),
        onPressed: () => widget.model.removeFavourite(thatFave!),
      );
    }

    return IconButton(
      icon: const Icon(Icons.favorite_border),
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext context) {
          TextEditingController c = TextEditingController();
          return AlertDialog(
            title: Text('Save Location',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
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
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await widget.model.addFavourite(location, c.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Edit Favourites Modal ───────────────────────────────────────────────

  void _showEditFavoritesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 400),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final colors = Theme.of(context).colorScheme;
            final texts = Theme.of(context).textTheme;
            final faves = widget.model.state.faves;

            return Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          Text('Edit Saved Locations',
                              style: texts.headlineSmall!.copyWith(
                                  color: colors.onSurface, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (faves.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('${faves.length}',
                                  style: texts.bodySmall!.copyWith(
                                      color: colors.onSecondaryContainer,
                                      fontWeight: FontWeight.w600)),
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
                                      color: colors.onSurfaceVariant.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('No saved locations yet',
                                      style: texts.titleMedium!
                                          .copyWith(color: colors.onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add locations to favorites to manage them here. \n'
                                    'Do this by searching for a station or location and tapping the heart icon.',
                                    style: texts.bodyMedium!.copyWith(
                                        color: colors.onSurfaceVariant.withOpacity(0.7)),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: faves.length,
                              onReorder: (oldIndex, newIndex) async {
                                if (newIndex > oldIndex) newIndex -= 1;
                                List<FavoriteLocation> reorderedFaves = List.from(faves);
                                final item = reorderedFaves.removeAt(oldIndex);
                                reorderedFaves.insert(newIndex, item);
                                setModalState(() {});
                                await widget.model.saveFavoriteOrder(reorderedFaves);
                                await widget.model.reloadFaves();
                                setModalState(() {});
                              },
                              itemBuilder: (context, index) {
                                final fave = faves[index];
                                return Padding(
                                  key: ValueKey('${fave.location.id}_$index'),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: colors.primaryContainer,
                                        child: Icon(
                                          fave.location is Station
                                              ? Icons.train
                                              : Icons.location_on,
                                          color: colors.onPrimaryContainer,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(fave.name,
                                          style: texts.titleMedium!.copyWith(
                                              color: colors.onSurface,
                                              fontWeight: FontWeight.w500)),
                                      subtitle: Text(fave.location.name,
                                          style: texts.bodySmall!
                                              .copyWith(color: colors.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined,
                                                color: colors.primary, size: 20),
                                            onPressed: () => _showRenameFavoriteDialog(
                                                context, fave, setModalState),
                                            tooltip: 'Rename',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: colors.error, size: 20),
                                            onPressed: () => _showDeleteFavoriteDialog(
                                                context, fave, setModalState),
                                            tooltip: 'Remove',
                                          ),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: colors.outline.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.drag_handle,
                                                  color: colors.onSurfaceVariant, size: 20),
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
  }

  void _showRenameFavoriteDialog(
      BuildContext context, FavoriteLocation fave, StateSetter setModalState) {
    final TextEditingController controller = TextEditingController(text: fave.name);
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Location',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(color: colors.onSurface)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await Localdatasaver.removeFavouriteLocation(fave);
                  await Localdatasaver.addLocationToFavourites(
                      fave.location, controller.text.trim());
                  await widget.model.reloadFaves();
                  setModalState(() {});
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

  void _showDeleteFavoriteDialog(
      BuildContext context, FavoriteLocation fave, StateSetter setModalState) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Location',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(color: colors.onSurface)),
          content: Text(
            'Are you sure you want to remove "${fave.name}" from your saved locations?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: colors.error, foregroundColor: colors.onError),
              onPressed: () async {
                await widget.model.removeFavourite(fave);
                setModalState(() {});
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