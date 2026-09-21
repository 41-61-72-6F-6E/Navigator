import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/navigator_maplibre_map.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/open_free_map_bright_layer.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/destinationComponent/destinationComponent.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/emptyState/emptyState.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/interchangeComponent/interchangeComponent.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/legWidget/legWidget.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/locationButton/locationButton.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/originComponent/originComponent.dart';
import 'package:navigator/widgets/journeyPage/UIComponents/walkingLeg/walkingLeg.dart';
import 'package:navigator/widgets/journeyPage/journeyPageModel.dart';
import 'package:navigator/widgets/GeneralUIComponents/sheetHandle/sheetHandle.dart';

/// Renders all UI for the Journey page.
/// Owns the sheet controller and observes [JourneyPageAndroidModel] for data
/// changes.
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

class _JourneyPageAndroidViewState extends State<JourneyPageAndroidView> {
  // ── Sheet constants ────────────────────────────────────────────────────────
  static const double _minChildSize = 0.15;
  static const double _maxChildSize = 1.0;
  static const double _initialChildSize = 0.6;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final Map<Leg, VoidCallback> _lineColorListeners = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    for (final entry in _lineColorListeners.entries) {
      entry.key.lineColorNotifier.removeListener(entry.value);
    }
    _lineColorListeners.clear();
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  // ── Animated map move ──────────────────────────────────────────────────────

  // ── Leg focus ──────────────────────────────────────────────────────────────

  void _focusMapOnLeg(Leg leg) {
    if (!mounted) return;

    print("Focusing map on leg: ${leg.origin.name} to ${leg.destination.name}");

    final (legCenter, legZoom) = widget.model.getLegFocusPoint(leg);

    print("Leg center: $legCenter, zoom: $legZoom");
    _sheetController.jumpTo(0.15);

    Future.microtask(() {
      unawaited(widget.model.moveMap(legCenter, legZoom));
    });
  }

  // ── User location ──────────────────────────────────────────────────────────

  void _centerOnUserLocation() {
    print("Location button pressed");
    final userLocation = widget.model.state.currentUserLocation;
    if (userLocation != null) {
      print("Centering on location: $userLocation");

      unawaited(widget.model.moveMap(userLocation, 18, animate: true));
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
        prevLeg.arrivalPlatformEffective !=
            nextLeg.departurePlatformEffective) {
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
              final newSize = (_sheetController.size - fractionDelta).clamp(
                _minChildSize,
                _maxChildSize,
              );
              _sheetController.jumpTo(newSize);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                            style: Theme.of(context).textTheme.headlineSmall!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                  leg.origin.ril100Ids,
                  leg.destination.ril100Ids,
                ))) {
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
        journeyComponents.add(
          DestinationComponent(design: widget.design, leg: leg),
        );
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

  List<NavigatorMapPoint> _buildStationPoints(BuildContext context) {
    final journey = widget.model.journey;
    final colors = Theme.of(context).colorScheme;
    final Set<String> addedStations = {};
    final List<NavigatorMapPoint> points = [];

    if (journey.legs.isNotEmpty) {
      final firstLeg = journey.legs.first;
      final startKey =
          '${firstLeg.origin.latitude},${firstLeg.origin.longitude}';
      if (!addedStations.contains(startKey)) {
        addedStations.add(startKey);
        points.add(
          _createStartFinishPoint(firstLeg.origin, colors, isStart: true),
        );
      }
    }

    for (final leg in journey.legs) {
      if (leg.isWalking != true && leg.lineName != null) {
        final originKey = '${leg.origin.latitude},${leg.origin.longitude}';
        if (!addedStations.contains(originKey)) {
          addedStations.add(originKey);
          points.add(
            _createStationPoint(
              leg.origin,
              colors,
              leg.lineColorNotifier.value,
            ),
          );
        }
        final destinationKey =
            '${leg.destination.latitude},${leg.destination.longitude}';
        if (!addedStations.contains(destinationKey)) {
          addedStations.add(destinationKey);
          points.add(
            _createStationPoint(
              leg.destination,
              colors,
              leg.lineColorNotifier.value,
            ),
          );
        }
      }
    }

    if (journey.legs.isNotEmpty) {
      final lastLeg = journey.legs.last;
      final endKey =
          '${lastLeg.destination.latitude},${lastLeg.destination.longitude}';
      if (!addedStations.contains(endKey)) {
        addedStations.add(endKey);
        points.add(
          _createStartFinishPoint(lastLeg.destination, colors, isStart: false),
        );
      }
    }

    return points;
  }

  NavigatorMapPoint _createStartFinishPoint(
    Station station,
    ColorScheme colors, {
    required bool isStart,
  }) {
    return NavigatorMapPoint(
      id: '${isStart ? 'start' : 'finish'}-${station.latitude}-${station.longitude}',
      point: LatLng(station.latitude, station.longitude),
      label: station.name,
      showLabel: true,
      labelColor: colors.onSurfaceVariant,
      labelHaloColor: colors.surfaceContainer,
      color: isStart ? colors.primary : colors.secondary,
      strokeColor: colors.surface,
      radius: 11,
      strokeWidth: 2,
      icon: isStart ? 'navigator-start' : 'navigator-finish',
      iconSize: 0.07,
      properties: {'kind': isStart ? 'journeyStart' : 'journeyFinish'},
    );
  }

  NavigatorMapPoint _createStationPoint(
    Station station,
    ColorScheme colors,
    Color? lineColor,
  ) {
    return NavigatorMapPoint(
      id: 'journey-station-${station.latitude}-${station.longitude}',
      point: LatLng(station.latitude, station.longitude),
      label: station.name,
      showLabel: true,
      labelColor: colors.onSurfaceVariant,
      labelHaloColor: colors.surfaceContainer,
      color: lineColor ?? colors.primary,
      strokeColor: colors.surface,
      radius: 10,
      strokeWidth: 2,
      icon: 'navigator-transit',
      iconSize: 0.07,
      properties: const {'kind': 'journeyStation'},
    );
  }

  // ── Map view ───────────────────────────────────────────────────────────────

  Widget _buildMapView(BuildContext context) {
    final state = widget.model.state;
    final points = <NavigatorMapPoint>[
      ..._buildStationPoints(context),
      if (state.currentUserLocation case final location?)
        _locationPoint(
          location,
          state.currentZoom,
          state.locationAccuracy,
          state.locationHeading,
        ),
    ];
    return Stack(
      children: [
        Positioned.fill(
          child: NavigatorMapLibreMap(
            idPrefix: 'journey',
            initialCenter: state.currentCenter,
            initialZoom: state.currentZoom,
            minZoom: 5,
            maxZoom: 18,
            lines: _extractPolylinesByLeg(),
            points: points,
            onMapReady: widget.model.attachMapCamera,
            onCameraChanged: (center, zoom, _) {
              widget.model.updateCurrentPosition(center, zoom);
            },
          ),
        ),
        const OpenFreeMapAttribution(alignment: Alignment.topRight),
        LocationButton(design: widget.design, onPressed: _centerOnUserLocation),
      ],
    );
  }

  // ── Polylines ──────────────────────────────────────────────────────────────

  List<NavigatorMapLine> _extractPolylinesByLeg() {
    List<NavigatorMapLine> polylines = [];
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

        final List<LatLng> legPoints = _extractPointsFromLegPolyline(
          leg.polyline,
        );
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
            _listenForLineColor(leg, cacheKey);
          }
        }

        final double strokeWidth = leg.isWalking == true ? 3.0 : 4.0;

        polylines.add(
          NavigatorMapLine(
            id: 'journey-leg-$i',
            points: legPoints,
            color: lineColor,
            width: strokeWidth,
            dashed: leg.isWalking == true,
            properties: {'kind': 'journey', 'legIndex': i},
          ),
        );
      }
    } catch (e) {
      print('Error creating polylines: $e');
    }

    return polylines;
  }

  void _listenForLineColor(Leg leg, String cacheKey) {
    if (_lineColorListeners.containsKey(leg)) return;
    void listener() {
      final color = leg.lineColorNotifier.value;
      if (mounted && color != null) {
        widget.model.updateTransitLineColorCache(cacheKey, color);
      }
    }

    _lineColorListeners[leg] = listener;
    leg.lineColorNotifier.addListener(listener);
    leg.initializeLineColor();
  }

  NavigatorMapPoint _locationPoint(
    LatLng location,
    double zoom,
    double accuracyMeters,
    double heading,
  ) {
    final metersPerPixel =
        156543.03392 *
        math.cos(location.latitude * math.pi / 180) /
        math.pow(2, zoom);
    final accuracyRadius = metersPerPixel <= 0
        ? 0.0
        : (accuracyMeters / metersPerPixel).clamp(0, 120).toDouble();
    return NavigatorMapPoint(
      id: 'journey-current-location',
      point: location,
      color: Colors.lightBlue.shade800,
      strokeColor: Colors.white,
      radius: 10,
      strokeWidth: 2,
      icon: 'navigator-location',
      iconSize: 0.07,
      heading: heading,
      accuracyRadius: accuracyRadius,
      accuracyColor: Colors.blue.shade200.withAlpha(0x20),
      properties: const {'kind': 'currentLocation'},
    );
  }

  List<LatLng> _extractPointsFromLegPolyline(dynamic polylineData) {
    List<LatLng> points = [];
    try {
      final Map<String, dynamic> geoJson = polylineData is Map<String, dynamic>
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
