import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/destinationComponent/destinationComponent.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/emptyState/emptyState.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/interchangeComponent/interchangeComponent.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/legWidget/legWidget.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/locationButton/locationButton.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/originComponent/originComponent.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/sheetHandle/sheetHandle.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/walkingLeg/walkingLeg.dart';
import 'package:navigator/widgets/journeyPage/journeyPageModel.dart';

/// Renders all UI for the Journey page.
/// Owns the sheet controller and map-animation controller (both require vsync /
/// are pure UI concerns). Observes [JourneyPageAndroidModel] for data changes.
class JourneyPageAndroidView extends StatefulWidget {
  final JourneyPageAndroidModel model;
  final int design;

  const JourneyPageAndroidView({
    super.key,
    required this.model,
    this.design = 0,
  });

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
    final zoomTween = Tween<double>(begin: currentZoomLevel, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

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
        prevLeg.arrivalPlatformEffective != nextLeg.departurePlatformEffective) {
      return 'Platform change: ${prevLeg.arrivalPlatformEffective} to ${nextLeg.departurePlatformEffective}';
    }
    return null;
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
                  SheetHandle(design: widget.design),
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
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (!widget.model.state.isSaved)
                          FilledButton.tonalIcon(
                            onPressed: () => widget.model.saveJourney(),
                            label: const Text('Save Journey'),
                            icon: const Icon(Icons.bookmark_outline),
                          ),
                        if (widget.model.state.isSaved)
                          FilledButton.tonalIcon(
                            onPressed: () => widget.model.removeSavedJourney(),
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

  // ── Journey content ────────────────────────────────────────────────────────

  Widget _buildJourneyContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final journey = widget.model.journey;

    if (journey.legs.isEmpty) {
      return EmptyState(design: widget.design);
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
        journeyComponents.add(OriginComponent(design: widget.design, leg: leg));
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
          for (int interchangeIndex = previousLegIndex + 1;
              interchangeIndex < legIndex;
              interchangeIndex++) {
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
          for (int searchIndex = previousLegIndex;
              searchIndex >= 0;
              searchIndex--) {
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
          final interchangeWidget = InterchangeComponent(
            design: widget.design,
            arrivingLeg: arrivingLeg,
            departingLeg: departingLeg,
            platformChangeText: platformChangeText,
            showInterchangeTime: showInterchangeTime,
          );
          journeyComponents.add(interchangeWidget);
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
          journeyComponents.add(
            WalkingLeg(
              design: widget.design,
              leg: leg,
              onMapPressed: () => _focusMapOnLeg(leg),
            ),
          );
        } else {
          journeyComponents.add(
            LegWidgetWrapper(
              design: widget.design,
              leg: leg,
              colorArg: leg.lineColorNotifier.value ?? Colors.grey,
              onMapPressed: () => _focusMapOnLeg(leg),
            ),
          );
        }
      }

      if (isLast) {
        journeyComponents
            .add(DestinationComponent(design: widget.design, leg: leg));
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: journeyComponents.length,
      itemBuilder: (context, index) => journeyComponents[index],
    );
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
        final originKey = '${leg.origin.latitude},${leg.origin.longitude}';
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  color: (isStart ? colors.primary : colors.secondary)
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                widget.model.updateCurrentPosition(camera.center, camera.zoom);
              }
              if (hasGesture &&
                  state.alignPositionOnUpdate != AlignOnUpdate.never) {
                widget.model.updateAlignPosition(AlignOnUpdate.never);
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
                accuracyCircleColor: Colors.blue[200]!.withAlpha(0x20),
                headingSectorColor: Colors.blue[400]!.withAlpha(0x90),
                headingSectorRadius: 60,
              ),
            ),
          ],
        ),
        LocationButton(design: widget.design, onPressed: _centerOnUserLocation),
      ],
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

          if (!widget.model.state.transitLineColorCache.containsKey(cacheKey) &&
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