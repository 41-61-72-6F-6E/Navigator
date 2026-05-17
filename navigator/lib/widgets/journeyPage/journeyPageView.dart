import 'dart:async';
import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/widgets/journeyPage/journeyPageModel.dart';

/// Renders all UI for the Journey page.
/// Owns the sheet controller and map-animation controller (both require vsync /
/// are pure UI concerns). Observes [JourneyPageAndroidModel] for data changes.
class JourneyPageAndroidView extends StatefulWidget {
  final JourneyPageAndroidModel model;

  const JourneyPageAndroidView({super.key, required this.model});

  @override
  State<JourneyPageAndroidView> createState() => _JourneyPageAndroidViewState();
}

class _JourneyPageAndroidViewState extends State<JourneyPageAndroidView>
    with SingleTickerProviderStateMixin {
  // ── Sheet constants ────────────────────────────────────────────────────────
  static const double _minChildSize = 0.15;
  static const double _maxChildSize = 1.0;
  static const double _initialChildSize = 0.6;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ── Map animation (needs vsync from this State) ───────────────────────────
  AnimationController? _mapMoveController;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _mapMoveController?.stop();
    _mapMoveController?.dispose();
    _mapMoveController = null;
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  // ── Animated map move ──────────────────────────────────────────────────────

  void animatedMapMove(
    LatLng currentPosition,
    double currentZoomLevel,
    LatLng destLocation,
    double destZoom,
  ) {
    // Cancel any running animation safely
    if (_mapMoveController != null) {
      _mapMoveController!.stop();
      _mapMoveController!.dispose();
      _mapMoveController = null;
    }

    final distanceKm = widget.model.calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      destLocation.latitude,
      destLocation.longitude,
    );

    // If absolutely identical, snap
    if (distanceKm < 1e-6 && (currentZoomLevel - destZoom).abs() < 0.001) {
      widget.model.mapController.move(destLocation, destZoom);
      return;
    }

    final latTween = Tween<double>(
      begin: currentPosition.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: currentPosition.longitude,
      end: destLocation.longitude,
    );
    final zoomTween =
        Tween<double>(begin: currentZoomLevel, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    final curve =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    void onTick() {
      if (!mounted) return;
      widget.model.mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    }

    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted) {
          widget.model.mapController.move(destLocation, destZoom);
          widget.model.updateCurrentPosition(destLocation, destZoom);
        }
        controller.removeListener(onTick);
        curve.removeStatusListener(onStatus);
        controller.dispose();
        if (identical(_mapMoveController, controller)) {
          _mapMoveController = null;
        }
      }
    }

    controller.addListener(onTick);
    curve.addStatusListener(onStatus);
    _mapMoveController = controller;
    controller.forward(from: 0);
  }

  // ── Leg focus ──────────────────────────────────────────────────────────────

  void _focusMapOnLeg(Leg leg) {
    if (!mounted) return;

    print("Focusing map on leg: ${leg.origin.name} to ${leg.destination.name}");

    final (legCenter, legZoom) = widget.model.getLegFocusPoint(leg);

    print("Leg center: $legCenter, zoom: $legZoom");
    _sheetController.jumpTo(0.15);

    Future.microtask(() {
      widget.model.updateAlignPosition(AlignOnUpdate.never);
      widget.model.mapController.move(legCenter, legZoom);
      widget.model.updateCurrentPosition(legCenter, legZoom);
    });
  }

  // ── User location ──────────────────────────────────────────────────────────

  void _centerOnUserLocation() {
    print("Location button pressed");
    final userLocation = widget.model.state.currentUserLocation;
    if (userLocation != null) {
      print("Centering on location: $userLocation");

      widget.model.updateAlignPosition(AlignOnUpdate.always);
      widget.model.alignPositionStreamController.add(18.0);

      animatedMapMove(
        widget.model.mapController.camera.center,
        widget.model.mapController.camera.zoom,
        userLocation,
        18.0,
      );
    } else {
      print("Cannot center: current user location is null");
    }
  }

  // ── Duration helper ────────────────────────────────────────────────────────

  String _formatLegDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '0min';
    final duration = end.difference(start);
    final minutes = (duration.inSeconds / 60).ceil();
    return minutes <= 0 ? '1min' : '${minutes}min';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [_buildMapView(context), _buildDraggableSheet(context)],
      ),
    );
  }

  // ── Draggable sheet ────────────────────────────────────────────────────────

  Widget _buildDraggableSheet(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _initialChildSize,
        minChildSize: _minChildSize,
        maxChildSize: _maxChildSize,
        snap: true,
        snapSizes: const [0.15, 0.4, 0.6, 1],
        builder: (context, scrollController) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              final fractionDelta =
                  details.primaryDelta! / MediaQuery.of(context).size.height;
              final newSize = (_sheetController.size - fractionDelta)
                  .clamp(_minChildSize, _maxChildSize);
              _sheetController.jumpTo(newSize);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSheetHandle(context),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16.0,
                      left: 24,
                      right: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Journey Details',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                          ),
                        ),
                        if (!widget.model.state.isSaved)
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                widget.model.saveJourney(),
                            label: const Text('Save Journey'),
                            icon: const Icon(Icons.bookmark_outline),
                          ),
                        if (widget.model.state.isSaved)
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                widget.model.removeSavedJourney(),
                            label: const Text('Journey Saved'),
                            icon: const Icon(Icons.bookmark),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildJourneyContent(context, scrollController),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetHandle(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Journey content ────────────────────────────────────────────────────────

  Widget _buildJourneyContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final journey = widget.model.journey;

    if (journey.legs.isEmpty) {
      return _buildEmptyState(context);
    }

    List<Widget> journeyComponents = [];
    List<int> actualLegIndices = [];

    for (int index = 0; index < journey.legs.length; index++) {
      final leg = journey.legs[index];
      final isSameStationInterchange =
          leg.origin.id == leg.destination.id &&
          leg.origin.name == leg.destination.name;
      if (!isSameStationInterchange) {
        actualLegIndices.add(index);
      }
    }

    for (int i = 0; i < actualLegIndices.length; i++) {
      final legIndex = actualLegIndices[i];
      final leg = journey.legs[legIndex];
      final isFirst = i == 0;
      final isLast = i == actualLegIndices.length - 1;

      if (isFirst) {
        journeyComponents.add(_buildOriginComponent(context, leg));
      }

      if (!isFirst) {
        final previousLegIndex = actualLegIndices[i - 1];
        final previousLeg = journey.legs[previousLegIndex];

        bool shouldShowInterchange = false;
        bool showInterchangeTime = true;
        String? platformChangeText;
        Leg arrivingLeg = previousLeg;
        Leg departingLeg = leg;

        if (legIndex - previousLegIndex > 1) {
          for (
            int interchangeIndex = previousLegIndex + 1;
            interchangeIndex < legIndex;
            interchangeIndex++
          ) {
            final interchangeLeg = journey.legs[interchangeIndex];
            if (interchangeLeg.origin.id == interchangeLeg.destination.id &&
                interchangeLeg.origin.name == interchangeLeg.destination.name) {
              shouldShowInterchange = true;
              platformChangeText = _getPlatformChangeText(
                interchangeLeg,
                interchangeIndex,
                journey.legs,
              );
              break;
            }
          }
        } else if (previousLeg.destination.id == leg.origin.id &&
            previousLeg.destination.name == leg.origin.name &&
            ((previousLeg.isWalking == true && leg.isWalking != true) ||
                (previousLeg.isWalking != true && leg.isWalking == true) ||
                (previousLeg.isWalking != true &&
                    leg.isWalking != true &&
                    previousLeg.lineName != leg.lineName))) {
          shouldShowInterchange = true;
          showInterchangeTime = false;

          if (previousLeg.arrivalPlatformEffective.isNotEmpty &&
              leg.departurePlatformEffective.isNotEmpty &&
              previousLeg.arrivalPlatformEffective !=
                  leg.departurePlatformEffective) {
            platformChangeText =
                'Platform change: ${previousLeg.arrivalPlatformEffective} to ${leg.departurePlatformEffective}';
          }
        }

        final isWithinStationComplex =
            previousLeg.destination.ril100Ids.isNotEmpty &&
            leg.origin.ril100Ids.isNotEmpty &&
            _haveSameRil100Station(
              previousLeg.destination.ril100Ids,
              leg.origin.ril100Ids,
            );

        if (isWithinStationComplex) {
          for (
            int searchIndex = previousLegIndex;
            searchIndex >= 0;
            searchIndex--
          ) {
            final searchLeg = journey.legs[searchIndex];
            if (searchLeg.isWalking != true &&
                _haveSameRil100Station(
                  searchLeg.destination.ril100Ids,
                  leg.origin.ril100Ids,
                )) {
              arrivingLeg = searchLeg;
              if (leg.isWalking != true) {
                shouldShowInterchange = true;
                showInterchangeTime = true;
                if (searchLeg.arrivalPlatformEffective.isNotEmpty &&
                    leg.departurePlatformEffective.isNotEmpty &&
                    searchLeg.arrivalPlatformEffective !=
                        leg.departurePlatformEffective) {
                  platformChangeText =
                      'Platform change: ${searchLeg.arrivalPlatformEffective} to ${leg.departurePlatformEffective}';
                }
              } else {
                shouldShowInterchange = false;
              }
              break;
            }
          }
        }

        if (!shouldShowInterchange &&
            leg.isWalking == true &&
            leg.origin.ril100Ids.isNotEmpty &&
            (leg.destination.ril100Ids.isEmpty ||
                !_haveSameRil100Station(
                    leg.origin.ril100Ids, leg.destination.ril100Ids))) {
          shouldShowInterchange = true;
          showInterchangeTime = false;
          if (previousLeg.arrivalPlatformEffective.isNotEmpty &&
              leg.departurePlatformEffective.isNotEmpty &&
              previousLeg.arrivalPlatformEffective !=
                  leg.departurePlatformEffective) {
            platformChangeText =
                'Platform change: ${previousLeg.arrivalPlatformEffective} to ${leg.departurePlatformEffective}';
          }
        }

        if (shouldShowInterchange) {
          final interchangeWidget = _buildInterchangeComponent(
            context,
            arrivingLeg,
            departingLeg,
            platformChangeText,
            showInterchangeTime,
          );
          if (interchangeWidget is! SizedBox ||
              (interchangeWidget).height != 0) {
            journeyComponents.add(interchangeWidget);
          }
        }
      }

      bool shouldDisplayLeg = true;
      if (leg.isWalking == true &&
          leg.origin.ril100Ids.isNotEmpty &&
          leg.destination.ril100Ids.isNotEmpty &&
          _haveSameRil100Station(
            leg.origin.ril100Ids,
            leg.destination.ril100Ids,
          )) {
        shouldDisplayLeg = false;
      }

      if (shouldDisplayLeg) {
        if (leg.isWalking == true) {
          journeyComponents
              .add(_buildWalkingLegNew(context, leg, i, journey.legs));
        } else {
          journeyComponents.add(
            LegWidget(
              leg: leg,
              colorArg: leg.lineColorNotifier.value ?? Colors.grey,
              onMapPressed: () => _focusMapOnLeg(leg),
            ),
          );
        }
      }

      if (isLast) {
        journeyComponents.add(_buildDestinationComponent(context, leg));
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: journeyComponents.length,
      itemBuilder: (context, index) => journeyComponents[index],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _haveSameRil100Station(List<String> ids1, List<String> ids2) {
    if (ids1.isEmpty || ids2.isEmpty) return false;
    for (final id1 in ids1) {
      for (final id2 in ids2) {
        if (id1 == id2) return true;
      }
    }
    return false;
  }

  String? _getPlatformChangeText(Leg leg, int index, List<Leg> legs) {
    if (leg.isWalking != true || index <= 0 || index >= legs.length - 1) {
      return null;
    }
    final prevLeg = legs[index - 1];
    final nextLeg = legs[index + 1];
    if (prevLeg.arrivalPlatformEffective.isNotEmpty &&
        nextLeg.departurePlatformEffective.isNotEmpty &&
        prevLeg.arrivalPlatformEffective !=
            nextLeg.departurePlatformEffective) {
      return 'Platform change: ${prevLeg.arrivalPlatformEffective} to ${nextLeg.departurePlatformEffective}';
    }
    return null;
  }

  // ── Station markers ────────────────────────────────────────────────────────

  List<Marker> _buildStationMarkers(BuildContext context) {
    final journey = widget.model.journey;
    final colors = Theme.of(context).colorScheme;
    final Set<String> addedStations = {};
    final List<Marker> markers = [];

    if (journey.legs.isNotEmpty) {
      final firstLeg = journey.legs.first;
      final startKey =
          '${firstLeg.origin.latitude},${firstLeg.origin.longitude}';
      if (!addedStations.contains(startKey)) {
        addedStations.add(startKey);
        markers.add(
            _createStartFinishMarker(firstLeg.origin, colors, isStart: true));
      }
    }

    for (final leg in journey.legs) {
      if (leg.isWalking != true && leg.lineName != null) {
        final originKey =
            '${leg.origin.latitude},${leg.origin.longitude}';
        if (!addedStations.contains(originKey)) {
          addedStations.add(originKey);
          markers.add(_createStationMarker(
              leg.origin, colors, leg.lineColorNotifier.value));
        }
        final destinationKey =
            '${leg.destination.latitude},${leg.destination.longitude}';
        if (!addedStations.contains(destinationKey)) {
          addedStations.add(destinationKey);
          markers.add(_createStationMarker(
              leg.destination, colors, leg.lineColorNotifier.value));
        }
      }
    }

    if (journey.legs.isNotEmpty) {
      final lastLeg = journey.legs.last;
      final endKey =
          '${lastLeg.destination.latitude},${lastLeg.destination.longitude}';
      if (!addedStations.contains(endKey)) {
        addedStations.add(endKey);
        markers.add(_createStartFinishMarker(lastLeg.destination, colors,
            isStart: false));
      }
    }

    return markers;
  }

  Marker _createStartFinishMarker(
    Station station,
    ColorScheme colors, {
    required bool isStart,
  }) {
    return Marker(
      point: LatLng(station.latitude, station.longitude),
      width: 150,
      height: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: isStart ? colors.primary : colors.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (isStart ? colors.primary : colors.secondary)
                          .withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(
              isStart ? Icons.trip_origin : Icons.location_on,
              color: colors.onPrimary,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Marker _createStationMarker(
    Station station,
    ColorScheme colors,
    Color? lineColor,
  ) {
    IconData iconData = Icons.location_on;
    if (station.subway) {
      iconData = Icons.subway;
    } else if (station.tram) {
      iconData = Icons.tram;
    } else if (station.suburban) {
      iconData = Icons.directions_subway;
    } else if (station.ferry) {
      iconData = Icons.directions_ferry;
    } else if (station.national || station.nationalExpress) {
      iconData = Icons.train;
    } else if (station.bus) {
      iconData = Icons.directions_bus;
    }

    return Marker(
      point: LatLng(station.latitude, station.longitude),
      width: 150,
      height: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: lineColor ?? colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (lineColor ?? colors.primary).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(iconData, color: colors.onPrimary, size: 14),
          ),
        ],
      ),
    );
  }

  // ── Origin / Destination ───────────────────────────────────────────────────

  Widget _buildOriginComponent(BuildContext context, Leg l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Tooltip(
                  message: l.origin.name,
                  child: Text(
                    l.origin.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    color:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          l.effectiveDepartureFormatted,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        if (l.departurePlatformEffective.isNotEmpty)
                          Text(
                            'Platform ${l.departurePlatformEffective}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
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
        ),
      ),
    );
  }

  Widget _buildDestinationComponent(BuildContext context, Leg l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Tooltip(
                  message: l.destination.name,
                  child: Text(
                    l.destination.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    color:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          l.effectiveArrivalFormatted,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        if (l.arrivalPlatformEffective.isNotEmpty)
                          Text(
                            'Platform ${l.arrivalPlatformEffective}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
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
        ),
      ),
    );
  }

  // ── Interchange ────────────────────────────────────────────────────────────

  Widget _buildInterchangeComponent(
    BuildContext context,
    Leg arrivingLeg,
    Leg departingLeg,
    String? platformChangeText,
    bool showInterchangeTime,
  ) {
    Color arrivalTimeColor = Theme.of(context).colorScheme.onSurface;
    Color departureTimeColor =
        Theme.of(context).colorScheme.onPrimaryContainer;
    Color arrivalPlatformColor = Theme.of(context).colorScheme.onSurface;
    Color departurePlatformColor =
        Theme.of(context).colorScheme.onPrimaryContainer;

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
    if (departingLeg.departurePlatform !=
        departingLeg.departurePlatformEffective) {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        color: colorScheme.surfaceContainerLowest,
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
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Arrival ${arrivingLeg.effectiveArrivalFormatted}',
                              style: textTheme.titleMedium!
                                  .copyWith(color: arrivalTimeColor),
                            ),
                            if (arrivingLeg.arrivalPlatform == null)
                              Text(
                                'at the Station',
                                style: textTheme.bodySmall!.copyWith(
                                    color: colorScheme.onSurface),
                              ),
                            if (arrivingLeg.arrivalPlatform != null)
                              Text(
                                'Platform ${arrivingLeg.effectiveArrivalPlatform}',
                                style: textTheme.bodySmall!
                                    .copyWith(color: arrivalPlatformColor),
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                departingLeg.origin.name,
                                style: textTheme.headlineMedium
                                    ?.copyWith(color: colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (departingLeg.departureDateTime
                                          .difference(
                                              arrivingLeg.arrivalDateTime)
                                          .inMinutes <
                                      4 &&
                                  showInterchangeTime)
                                Text(
                                  'Interchange Time: ${departingLeg.departureDateTime.difference(arrivingLeg.arrivalDateTime).inMinutes} min',
                                  style: textTheme.titleSmall!
                                      .copyWith(color: colorScheme.error),
                                ),
                              if (departingLeg.departureDateTime
                                          .difference(
                                              arrivingLeg.arrivalDateTime)
                                          .inMinutes >=
                                      4 &&
                                  showInterchangeTime)
                                Text(
                                  'Interchange Time: ${departingLeg.departureDateTime.difference(arrivingLeg.arrivalDateTime).inMinutes} min',
                                  style: textTheme.titleSmall!.copyWith(
                                      color: colorScheme.onSurface),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 60,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 16,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(16)),
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
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Departure ${departingLeg.effectiveDepartureFormatted}',
                                          style: textTheme.titleMedium!
                                              .copyWith(
                                                  color:
                                                      departureTimeColor),
                                        ),
                                        if (departingLeg.departurePlatform ==
                                            null)
                                          Text(
                                            'at the Station',
                                            style: textTheme.bodyMedium!
                                                .copyWith(
                                                    color: colorScheme
                                                        .onPrimaryContainer),
                                          ),
                                        if (departingLeg.departurePlatform !=
                                            null)
                                          Text(
                                            'Platform ${departingLeg.effectiveDeparturePlatform}',
                                            style: textTheme.bodyMedium!
                                                .copyWith(
                                                    color:
                                                        departurePlatformColor),
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

  // ── Walking leg ────────────────────────────────────────────────────────────

  Widget _buildWalkingLegNew(
      BuildContext context, Leg leg, int index, List<Leg> legs) {
    if (leg.distance == null || leg.distance == 0) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                          width: (constraints.maxWidth / 100) * 12),
                      const Icon(Icons.directions_walk),
                      const SizedBox(width: 8),
                      Text(
                        'Walk ${leg.distance}m (${_formatLegDuration(leg.departureDateTime, leg.arrivalDateTime)})',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const Spacer(),
                      IconButton.filled(
                        onPressed: () => _focusMapOnLeg(leg),
                        icon: const Icon(Icons.map),
                        color: Theme.of(context).colorScheme.tertiary,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                right: constraints.maxWidth / 100 * 88,
                left: constraints.maxWidth / 100 * 6,
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                      radius: const Radius.circular(24)),
                  child: Container(
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Platform change text ───────────────────────────────────────────────────

  Widget _buildPlatformChangeText(
      BuildContext context, String platformChangeText) {
    final parts = platformChangeText.split(' to ');
    if (parts.length != 2) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          parts[0],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward,
              size: 14, color: Theme.of(context).colorScheme.tertiary),
        ),
        Flexible(
          child: Text(
            parts[1],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No journeys found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }

  // ── Map view ───────────────────────────────────────────────────────────────

  Widget _buildMapView(BuildContext context) {
    final state = widget.model.state;
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.model.mapController,
          options: MapOptions(
            initialCenter: state.currentCenter,
            initialZoom: state.currentZoom,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.flingAnimation |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.rotate,
              rotationThreshold: 20.0,
              pinchZoomThreshold: 0.5,
              pinchMoveThreshold: 40.0,
            ),
            onPositionChanged: (MapCamera camera, bool hasGesture) {
              if (mounted) {
                widget.model.updateCurrentPosition(
                    camera.center, camera.zoom);
              }
              if (hasGesture &&
                  state.alignPositionOnUpdate != AlignOnUpdate.never) {
                widget.model
                    .updateAlignPosition(AlignOnUpdate.never);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            _buildPolylineLayer(),
            MarkerLayer(markers: _buildStationMarkers(context)),
            CurrentLocationLayer(
              alignPositionStream:
                  widget.model.alignPositionStreamController.stream,
              alignPositionOnUpdate: state.alignPositionOnUpdate,
              style: LocationMarkerStyle(
                marker: DefaultLocationMarker(color: Colors.lightBlue[800]!),
                markerSize: const Size(20, 20),
                markerDirection: MarkerDirection.heading,
                accuracyCircleColor:
                    Colors.blue[200]!.withAlpha(0x20),
                headingSectorColor:
                    Colors.blue[400]!.withAlpha(0x90),
                headingSectorRadius: 60,
              ),
            ),
          ],
        ),
        _buildLocationButton(context),
      ],
    );
  }

  Widget _buildLocationButton(BuildContext context) {
    return Positioned(
      right: 20.0,
      bottom: 116.0,
      child: Material(
        elevation: 4.0,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: _centerOnUserLocation,
          child: Container(
            width: 56.0,
            height: 56.0,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.my_location,
              color: Theme.of(context)
                  .colorScheme
                  .tertiary
                  .withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ── Polylines ──────────────────────────────────────────────────────────────

  Widget _buildPolylineLayer() {
    final List<Polyline> polylines = _extractPolylinesByLeg();

    if (polylines.isEmpty) {
      print("DEBUG: No polylines created for journey legs");
      return const SizedBox.shrink();
    }

    print("DEBUG: Created ${polylines.length} polylines for journey legs");
    return PolylineLayer(polylines: polylines);
  }

  List<Polyline> _extractPolylinesByLeg() {
    List<Polyline> polylines = [];
    final Map<String, Color> modeColors = {
      'train': const Color(0xFF9C27B0),
      'subway': const Color(0xFF0075BF),
      'tram': const Color(0xFFE4000F),
      'bus': const Color(0xFF9A258F),
      'ferry': const Color(0xFF0098D8),
      'walking': Colors.grey,
      'default': Colors.blue,
    };

    try {
      for (int i = 0; i < widget.model.journey.legs.length; i++) {
        final leg = widget.model.journey.legs[i];
        if (leg.polyline == null) continue;

        final List<LatLng> legPoints =
            _extractPointsFromLegPolyline(leg.polyline);
        if (legPoints.isEmpty) continue;

        Color lineColor;

        if (leg.isWalking == true) {
          lineColor = modeColors['walking']!;
        } else {
          final String cacheKey =
              '${leg.lineName ?? ''}-${leg.productName ?? ''}';
          final String productType =
              leg.productName?.toLowerCase() ?? 'default';

          lineColor =
              widget.model.state.transitLineColorCache[cacheKey] ??
              modeColors[productType] ??
              modeColors['default']!;

          if (!widget.model.state.transitLineColorCache
                  .containsKey(cacheKey) &&
              leg.lineName != null &&
              leg.lineName!.isNotEmpty &&
              legPoints.isNotEmpty) {
            leg.lineColorNotifier.addListener(() {
              if (mounted) {
                widget.model.updateTransitLineColorCache(
                  cacheKey,
                  leg.lineColorNotifier.value as Color,
                );
              }
            });
          }
        }

        final double strokeWidth = leg.isWalking == true ? 3.0 : 4.0;

        polylines.add(
          Polyline(
            points: legPoints,
            color: lineColor,
            strokeWidth: strokeWidth,
            pattern: leg.isWalking == true
                ? StrokePattern.dotted()
                : StrokePattern.solid(),
          ),
        );
      }
    } catch (e) {
      print('Error creating polylines: $e');
    }

    return polylines;
  }

  List<LatLng> _extractPointsFromLegPolyline(dynamic polylineData) {
    List<LatLng> points = [];
    try {
      final Map<String, dynamic> geoJson =
          polylineData is Map<String, dynamic>
              ? polylineData
              : jsonDecode(polylineData);

      if (geoJson['type'] == 'FeatureCollection' &&
          geoJson['features'] is List) {
        for (final feature in geoJson['features'] as List) {
          if (feature['geometry'] != null &&
              feature['geometry']['type'] == 'Point' &&
              feature['geometry']['coordinates'] is List) {
            final List coords = feature['geometry']['coordinates'];
            if (coords.length >= 2) {
              final double lng = coords[0] is double
                  ? coords[0]
                  : double.parse(coords[0].toString());
              final double lat = coords[1] is double
                  ? coords[1]
                  : double.parse(coords[1].toString());
              points.add(LatLng(lat, lng));
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing leg polyline points: $e');
    }
    return points;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LegWidget  (unchanged from original)
// ═══════════════════════════════════════════════════════════════════════════

class LegWidget extends StatefulWidget {
  final Leg leg;
  Color colorArg;
  final VoidCallback? onMapPressed;

  LegWidget({
    super.key,
    required this.leg,
    required this.colorArg,
    this.onMapPressed,
  });

  @override
  State<LegWidget> createState() => _LegWidgetState();
}

class _LegWidgetState extends State<LegWidget> {
  bool _isExpanded = false;
  Remark? comfortCheckinRemark;
  Remark? bicycleRemark;
  Remark? infoRemark;
  late VoidCallback _colorListener;
  Color lineColor = Colors.grey;
  Color onLineColor = Colors.black;

  @override
  void initState() {
    super.initState();
    lineColor = widget.colorArg;
    try {
      comfortCheckinRemark = widget.leg.remarks!
          .firstWhere((r) => r.summary == 'Komfort-Checkin available');
    } catch (_) {
      comfortCheckinRemark = null;
    }
    try {
      bicycleRemark = widget.leg.remarks!
          .firstWhere((r) => r.summary == 'bicycles conveyed');
    } catch (_) {
      bicycleRemark = null;
    }
    try {
      infoRemark =
          widget.leg.remarks!.firstWhere((r) => r.type == 'status');
    } catch (_) {
      infoRemark = null;
    }

    final brightness = ThemeData.estimateBrightnessForColor(lineColor);
    onLineColor =
        brightness == Brightness.light ? Colors.black : Colors.white;

    _colorListener = () {
      if (mounted) {
        setState(() {
          lineColor = widget.leg.lineColorNotifier.value ?? Colors.grey;
          final b = ThemeData.estimateBrightnessForColor(lineColor);
          onLineColor =
              b == Brightness.light ? Colors.black : Colors.white;
        });
      }
    };
    widget.leg.lineColorNotifier.addListener(_colorListener);
  }

  @override
  void dispose() {
    widget.leg.lineColorNotifier.removeListener(_colorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intermediateStops = widget.leg.stopovers.length > 2
        ? widget.leg.stopovers.sublist(1, widget.leg.stopovers.length - 1)
        : <Stopover>[];
    final stopOrStops = intermediateStops.length == 1 ? 'stop' : 'stops';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final hasIntermediateStops = widget.leg.stopovers.length > 2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: lineColor.withAlpha(100),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                              width: (constraints.maxWidth / 100) * 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.leg.lineName != null &&
                                    widget.leg.lineName!.isNotEmpty)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: lineColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.leg.lineName!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge!
                                              .copyWith(color: onLineColor),
                                        ),
                                      ),
                                      if (widget.leg.direction != null &&
                                          widget.leg.direction!.isNotEmpty)
                                        const SizedBox(width: 8),
                                      if (widget.leg.direction != null &&
                                          widget.leg.direction!.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            widget.leg.direction!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                                    color: onLineColor),
                                            overflow:
                                                TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.start,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    if (comfortCheckinRemark != null)
                                      remark(context, comfortCheckinRemark!),
                                    if (bicycleRemark != null)
                                      remark(context, bicycleRemark!),
                                  ],
                                ),
                                if (infoRemark != null)
                                  info(context, infoRemark!),
                                if (!hasIntermediateStops)
                                  FilledButton.tonal(
                                    onPressed: () {},
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStateProperty.all(
                                        ThemeData.estimateBrightnessForColor(
                                                    lineColor) ==
                                                Brightness.dark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                      ),
                                      foregroundColor:
                                          WidgetStateProperty.all(
                                        ThemeData.estimateBrightnessForColor(
                                                    lineColor) ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                    child: const Text('No intermediate stops'),
                                  ),
                                if (hasIntermediateStops)
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    label: Text(_isExpanded
                                        ? 'Hide ${intermediateStops.length} $stopOrStops'
                                        : 'Show ${intermediateStops.length} $stopOrStops'),
                                    icon: AnimatedRotation(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      turns: _isExpanded ? .5 : 0,
                                      child: const Icon(
                                          Icons.arrow_drop_down),
                                    ),
                                    iconAlignment: IconAlignment.end,
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStateProperty.all(
                                              lineColor.withAlpha(120)),
                                      foregroundColor:
                                          WidgetStateProperty.all(
                                              onLineColor),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 80),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildStopsList(context),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                right: constraints.maxWidth / 100 * 88,
                left: constraints.maxWidth / 100 * 6,
                child: Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 16,
                child: IconButton.filled(
                  onPressed: widget.onMapPressed,
                  icon: const Icon(Icons.map),
                  color: Theme.of(context).colorScheme.tertiary,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopsList(BuildContext context) {
    final intermediateStops = widget.leg.stopovers.length > 2
        ? widget.leg.stopovers.sublist(1, widget.leg.stopovers.length - 1)
        : <Stopover>[];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              (constraints.maxWidth / 100) * 12 + 16, 0, 16 + 80, 16),
          child: Container(
            decoration: BoxDecoration(
              color: lineColor.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: lineColor.withAlpha(100), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: intermediateStops.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: lineColor.withAlpha(100)),
                  itemBuilder: (context, index) =>
                      _buildStopItem(context, intermediateStops[index]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStopItem(BuildContext context, Stopover stopover) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stopover.station.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onLineColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (stopover.effectiveArrivalDateTimeLocal != null)
                Text(
                  'Arr: ${_formatTime(stopover.effectiveArrivalDateTimeLocal!)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onLineColor),
                ),
              if (stopover.effectiveDepartureDateTimeLocal != null)
                Text(
                  'Dep: ${_formatTime(stopover.effectiveDepartureDateTimeLocal!)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onLineColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatModifiedDate(String? modifiedStr) {
    if (modifiedStr == null || modifiedStr.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(modifiedStr);
      if (dateTime.isUtc) dateTime = dateTime.toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    } catch (_) {
      return modifiedStr;
    }
  }

  void _showInformationPopup(BuildContext context, Remark remark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remark.summary ?? 'Information',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
              if (remark.modified != null) const SizedBox(height: 4),
              Text(
                'Last updated: ${_formatModifiedDate(remark.modified)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (remark.text != null && remark.text!.isNotEmpty)
                Text(
                  remark.text!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showRemarkPopup(BuildContext context, Remark remark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              _getRemarkIcon(remark.summary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remark.summary ?? 'Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (remark.text != null && remark.text!.isNotEmpty)
                Text(
                  remark.text!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _getRemarkIcon(String? summary) {
    switch (summary) {
      case 'Komfort-Checkin available':
        return Icon(Icons.check_circle_outline,
            size: 20, color: Theme.of(context).colorScheme.primary);
      case 'bicycles conveyed':
        return Icon(Icons.pedal_bike_outlined,
            size: 20, color: Theme.of(context).colorScheme.secondary);
      default:
        return Icon(Icons.info_outline,
            size: 20, color: Theme.of(context).colorScheme.tertiary);
    }
  }

  Widget info(BuildContext context, Remark remark) {
    return FilledButton.tonalIcon(
      onPressed: () => _showInformationPopup(context, remark),
      label: const Text('Further Information'),
      icon: const Icon(Icons.chevron_right),
      iconAlignment: IconAlignment.end,
      style: ButtonStyle(
        backgroundColor:
            WidgetStateProperty.all(lineColor.withAlpha(120)),
        foregroundColor: WidgetStateProperty.all(onLineColor),
      ),
    );
  }

  Widget remark(BuildContext context, Remark remark) {
    Icon icon = const Icon(Icons.power_off);
    switch (remark.summary) {
      case 'Komfort-Checkin available':
        icon = const Icon(Icons.check_circle_outline, size: 12);
        break;
      case 'bicycles conveyed':
        icon = const Icon(Icons.pedal_bike_outlined, size: 12);
        break;
    }

    if (remark.summary == null || remark.summary!.isEmpty) {
      return const SizedBox.shrink();
    }

    return IntrinsicWidth(
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () => _showRemarkPopup(context, remark),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    remark.summary!,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: onLineColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}