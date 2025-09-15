import 'dart:async';
import 'dart:math' as math;
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/pages/android/shared_bottom_navigation_android.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'dart:convert';
import 'package:navigator/models/station.dart';
import 'package:navigator/services/localDataSaver.dart';

import 'package:navigator/services/overpassApi.dart';
import 'package:navigator/services/overpassApi.dart' as overpassApi;

import '../../models/stopover.dart';


class JourneyPageAndroid extends StatefulWidget {
  final JourneyPage page;
  final Journey journey;

  const JourneyPageAndroid(this.page, {super.key, required this.journey});

  @override
  State<JourneyPageAndroid> createState() => _JourneyPageAndroidState();
}

class _JourneyPageAndroidState extends State<JourneyPageAndroid>
    with SingleTickerProviderStateMixin {
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  bool _isSaved = false;

  // Sheet controller for the draggable bottom sheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Sheet size constants
  static const double _minChildSize = 0.15;
  static const double _maxChildSize = 1.0;
  static const double _initialChildSize = 0.6;

  // Map-related variables
  LatLng? _currentUserLocation;
  LatLng _currentCenter = const LatLng(52.513416, 13.412364); // Berlin default
  double _currentZoom = 10;
  final MapController _mapController = MapController();

  // Location tracking variables
  late StreamController<LocationMarkerPosition> _locationStreamController;
  late StreamController<LocationMarkerHeading> _headingStreamController;
  StreamSubscription<Position>? _geolocatorSubscription;

  AnimationController? _mapMoveController;

  @override
  void initState() {
    super.initState();
    _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignPositionStreamController = StreamController<double?>();
    _initializeLocationTracking();
    updateIsSaved();
    _centerMapOnJourney();
  }

  @override
  void dispose() {
    // Clean up the stream controllers and subscription
    _locationStreamController.close();
    _headingStreamController.close();
    _geolocatorSubscription?.cancel();
    _alignPositionStreamController.close();

    _mapMoveController?.stop();
    _mapMoveController?.dispose();
    _mapMoveController = null;
    super.dispose();
  }

  Future<void> updateIsSaved() async
  {
    bool s = await Localdatasaver.journeyIsSaved(widget.journey);
    setState(() {
      _isSaved = s;
    });
  }

  void _centerMapOnJourney() {
    final journey = widget.journey;
    if (journey.legs.isEmpty) return;

    // Get start and end points of the journey
    final firstLeg = journey.legs.first;
    final lastLeg = journey.legs.last;

    final startLat = firstLeg.origin.latitude;
    final startLng = firstLeg.origin.longitude;
    final endLat = lastLeg.destination.latitude;
    final endLng = lastLeg.destination.longitude;

    // Calculate center point between start and end
    final centerLat = (startLat + endLat) / 2;
    final centerLng = (startLng + endLng) / 2;

    _currentCenter = LatLng(centerLat, centerLng);

    // Calculate appropriate zoom level based on distance
    final distance = _calculateDistance(startLat, startLng, endLat, endLng);
    _currentZoom = _calculateZoomLevel(distance);
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _calculateZoomLevel(double distanceKm) {
    if (distanceKm < 1) return 17.0;
    if (distanceKm < 5) return 14.0;
    if (distanceKm < 20) return 12.0;
    if (distanceKm < 50) return 10.0;
    if (distanceKm < 200) return 8.0;
    return 6.0;
  }

  void animatedMapMove(LatLng currentPosition, double currentZoomLevel, LatLng destLocation, double destZoom) {
    // Cancel any running animation safely
    if (_mapMoveController != null) {
      _mapMoveController!.stop();
      _mapMoveController!.dispose();
      _mapMoveController = null;
    }

    final distanceKm = _calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      destLocation.latitude,
      destLocation.longitude,
    );

    // If absolutely identical, snap
    if (distanceKm < 1e-6 && (currentZoomLevel - destZoom).abs() < 0.001) {
      _mapController.move(destLocation, destZoom);
      return;
    }

    final latTween = Tween<double>(begin: currentPosition.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: currentPosition.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: currentZoomLevel, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    void onTick() {
      if (!mounted) return;
      final newLat = latTween.evaluate(curve);
      final newLng = lngTween.evaluate(curve);
      final newZoom = zoomTween.evaluate(curve);
      _mapController.move(LatLng(newLat, newLng), newZoom);
    }

    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (mounted) {
          // Snap to the final destination to ensure accuracy
          _mapController.move(destLocation, destZoom);

          // Update state variables to match the final position
          setState(() {
            _currentCenter = destLocation;
            _currentZoom = destZoom;
          });
        }
        controller.removeListener(onTick);
        curve.removeStatusListener(onStatus); // This was incorrectly adding a listener in your code
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

  void _focusMapOnLeg(Leg leg) {
    if (!mounted) return;



    print("Focusing map on leg: ${leg.origin.name} to ${leg.destination.name}");

    final startLat = leg.origin.latitude;
    final startLng = leg.origin.longitude;
    final endLat = leg.destination.latitude;
    final endLng = leg.destination.longitude;

    // Create bounding box
    final double north = math.max(startLat, endLat);
    final double south = math.min(startLat, endLat);
    final double east = math.max(startLng, endLng);
    final double west = math.min(startLng, endLng);

    // Add padding (20%)
    final latPadding = (north - south) * 0.2;
    final lngPadding = (east - west) * 0.2;

    final centerLat = (north + south) / 2;
    final centerLng = (east + west) / 2;
    final legCenter = LatLng(centerLat, centerLng);

    final distanceKm = _calculateDistance(startLat, startLng, endLat, endLng);
    final legZoom = _calculateLegZoom(distanceKm);

    print("Leg center: $legCenter, zoom: $legZoom");
    _sheetController.jumpTo(0.15);

    // SIMPLIFIED APPROACH: Direct map movement with a slight delay
    Future.microtask(() {
      // Temporarily disable any automatic positioning
      setState(() {
        _alignPositionOnUpdate = AlignOnUpdate.never;
      });

      // Move map directly to target position
      _mapController.move(legCenter, legZoom);

      // Update state variables to match the new position
      setState(() {
        _currentCenter = legCenter;
        _currentZoom = legZoom;
      });
    });
  }

  double _calculateLegZoom(double distanceKm) {
    // More granular zoom levels based on distance
    if (distanceKm < 1) return 18.0;
    if (distanceKm < 3) return 15.0;
    if (distanceKm < 5) return 13.0;
    if (distanceKm < 7) return 12.0;
    if (distanceKm < 10) return 11.0;
    if (distanceKm < 15) return 10.0;
    if (distanceKm < 30) return 9.0;
    if (distanceKm < 50) return 8.0;
    if (distanceKm < 70) return 7.0;
    if (distanceKm < 150) return 6.0;
    if (distanceKm < 300) return 5.0;
    return 4.0;
  }

  void _initializeLocationTracking() {
    _locationStreamController = StreamController<LocationMarkerPosition>();
    _headingStreamController = StreamController<LocationMarkerHeading>();

    // Note: A production app should handle location permissions.
    _geolocatorSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          final locationMarkerPosition = LocationMarkerPosition(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
          );

          final locationMarkerHeading = LocationMarkerHeading(
            heading: position.heading * math.pi / 180,
            accuracy: position.headingAccuracy * math.pi / 180,
          );

          _handleLocationUpdate(locationMarkerPosition);

          if (!_locationStreamController.isClosed) {
            _locationStreamController.add(locationMarkerPosition);
          }
          if (!_headingStreamController.isClosed) {
            _headingStreamController.add(locationMarkerHeading);
          }
        });
  }

  void _handleLocationUpdate(LocationMarkerPosition position) {
    setState(() {
      _currentUserLocation = position.latLng;
    });
  }

  String _formatLegDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '0min';

    // Calculate duration with timezone awareness
    final duration = end.difference(start);
    final minutes = (duration.inSeconds / 60).ceil();

    return minutes <= 0 ? '1min' : '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [_buildMapView(context), _buildDraggableSheet(context)],
      ),
            bottomNavigationBar: SharedBottomNavigation(),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _initialChildSize,
        minChildSize: _minChildSize,
        maxChildSize: _maxChildSize,
        snap: true,
        snapSizes: [0.15, 0.4, 0.6, 1],
        builder: (context, scrollController) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              final fractionDelta = details.primaryDelta! / MediaQuery.of(context).size.height;
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
                    _buildSheetHandle(context),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0, left: 24, right: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Journey Details', style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),),
                              ),
                              if(!_isSaved)
                              FilledButton.tonalIcon(onPressed: () => {
                                Localdatasaver.saveJourney(widget.journey).then((_) {updateIsSaved();})
                              }, label: Text('Save Journey'), icon: const Icon(Icons.bookmark_outline)),
                              if(_isSaved)
                              FilledButton.tonalIcon(onPressed: () => {
                                Localdatasaver.removeSavedJourney(widget.journey).then((_) {updateIsSaved();}),
                              }, label: Text('Journey Saved'), icon: const Icon(Icons.bookmark)),
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

  Widget _buildJourneyContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final journey = widget.journey;

    if (journey.legs.isEmpty) {
      return _buildEmptyState(context);
    }

    // Build components for actual travel legs (not same-station interchanges)
    List<Widget> journeyComponents = [];
    List<int> actualLegIndices = [];

    // First, identify which legs are actual travel vs same-station interchanges
    for (int index = 0; index < journey.legs.length; index++) {
      final leg = journey.legs[index];

      // Skip legs that are same-station interchanges (same origin and destination)
      bool isSameStationInterchange =
          leg.origin.id == leg.destination.id &&
          leg.origin.name == leg.destination.name;

      if (!isSameStationInterchange) {
        actualLegIndices.add(index);
      }
    }

    // Build components for actual legs
    for (int i = 0; i < actualLegIndices.length; i++) {
      final legIndex = actualLegIndices[i];
      final leg = journey.legs[legIndex];
      final isFirst = i == 0;
      final isLast = i == actualLegIndices.length - 1;

      // Add origin component for first actual leg
      if (isFirst) {
        journeyComponents.add(_buildOriginComponent(context, leg));
      }

      // Check if there's an interchange between this leg and the previous actual leg
      if (!isFirst) {
        final previousLegIndex = actualLegIndices[i - 1];
        final previousLeg = journey.legs[previousLegIndex];

        // Check if we need to show an interchange component
        bool shouldShowInterchange = false;
        bool showInterchangeTime = true;
        String? platformChangeText;
        Leg arrivingLeg = previousLeg;
        Leg departingLeg = leg;

        // Case 1: There are legs between previous and current that represent interchanges
        if (legIndex - previousLegIndex > 1) {
          // Find the interchange leg(s) between them
          for (
            int interchangeIndex = previousLegIndex + 1;
            interchangeIndex < legIndex;
            interchangeIndex++
          ) {
            final interchangeLeg = journey.legs[interchangeIndex];

            // If this is a same-station interchange
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
        }
        // Case 2: Direct connection between different modes (e.g., walking to transit)
        else if (previousLeg.destination.id == leg.origin.id &&
            previousLeg.destination.name == leg.origin.name &&
            ((previousLeg.isWalking == true && leg.isWalking != true) ||
                (previousLeg.isWalking != true && leg.isWalking == true) ||
                (previousLeg.isWalking != true &&
                    leg.isWalking != true &&
                    previousLeg.lineName != leg.lineName))) {
          shouldShowInterchange = true;
          showInterchangeTime = false;

          // Check for platform changes
          if (previousLeg.arrivalPlatformEffective.isNotEmpty &&
              leg.departurePlatformEffective.isNotEmpty &&
              previousLeg.arrivalPlatformEffective !=
                  leg.departurePlatformEffective) {
            platformChangeText =
                'Platform change: ${previousLeg.arrivalPlatformEffective} to ${leg.departurePlatformEffective}';
          }
        }

        // Check if we're in the same station complex - this affects interchange logic
        bool isWithinStationComplex =
            previousLeg.destination.ril100Ids.isNotEmpty &&
            leg.origin.ril100Ids.isNotEmpty &&
            _haveSameRil100Station(
              previousLeg.destination.ril100Ids,
              leg.origin.ril100Ids,
            );

        // Special handling: If we're in the same station complex, consolidate the interchange
        if (isWithinStationComplex) {
          // Look backwards to find the last non-walking leg that brought us to this station complex
          for (
            int searchIndex = previousLegIndex;
            searchIndex >= 0;
            searchIndex--
          ) {
            final searchLeg = journey.legs[searchIndex];

            // If this leg's destination is in the same station complex and it's not a walking leg
            if (searchLeg.isWalking != true &&
                _haveSameRil100Station(
                  searchLeg.destination.ril100Ids,
                  leg.origin.ril100Ids,
                )) {
              arrivingLeg = searchLeg;

              // Only show interchange if the current leg is not walking (i.e., we're exiting the station complex)
              if (leg.isWalking != true) {
                shouldShowInterchange = true;
                showInterchangeTime = true;

                // Check for platform changes between the actual arriving leg and departing leg
                if (searchLeg.arrivalPlatformEffective.isNotEmpty &&
                    leg.departurePlatformEffective.isNotEmpty &&
                    searchLeg.arrivalPlatformEffective !=
                        leg.departurePlatformEffective) {
                  platformChangeText =
                      'Platform change: ${searchLeg.arrivalPlatformEffective} to ${leg.departurePlatformEffective}';
                }
              } else {
                // This is a walking leg within the station complex, don't show interchange yet
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
             !_haveSameRil100Station(leg.origin.ril100Ids, leg.destination.ril100Ids))) {
          shouldShowInterchange = true;
          showInterchangeTime = false;

          // Check for platform changes between previousLeg and walking leg
          if (previousLeg.arrivalPlatformEffective.isNotEmpty &&
              leg.departurePlatformEffective.isNotEmpty &&
              previousLeg.arrivalPlatformEffective != leg.departurePlatformEffective) {
            platformChangeText =
                'Platform change: ${previousLeg.arrivalPlatformEffective} to ${leg.departurePlatformEffective}';
          }
        }

        // Only add interchange component if it should be shown
        if (shouldShowInterchange) {
          Widget interchangeWidget = _buildInterchangeComponent(
            context,
            arrivingLeg, // This might be a leg from earlier if we're consolidating within station complex
            departingLeg,
            platformChangeText,
            showInterchangeTime,
          );

          // Only add if it's not a SizedBox.shrink or empty container
          if (interchangeWidget is! SizedBox ||
              (interchangeWidget).height != 0) {
            journeyComponents.add(interchangeWidget);
          }
        }
      }

      // Check if this leg should be displayed
      bool shouldDisplayLeg = true;

      // Hide walking legs that are within the same station complex
      if (leg.isWalking == true &&
          leg.origin.ril100Ids.isNotEmpty &&
          leg.destination.ril100Ids.isNotEmpty &&
          _haveSameRil100Station(
            leg.origin.ril100Ids,
            leg.destination.ril100Ids,
          )) {
        shouldDisplayLeg = false;
      }

      // Add the actual leg component only if it should be displayed
      if (shouldDisplayLeg) {
        if (leg.isWalking == true) {
          journeyComponents.add(
            _buildWalkingLegNew(context, leg, i , journey.legs),
          );
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

      // Add destination component for last actual leg
      if (isLast) {
        journeyComponents.add(_buildDestinationComponent(context, leg));
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: journeyComponents.length,
      itemBuilder: (context, index) {
        return journeyComponents[index];
      },
    );
  }

  // Helper method to check if two lists of RIL100 IDs have any overlap
  bool _haveSameRil100Station(
    List<String> ril100Ids1,
    List<String> ril100Ids2,
  ) {
    if (ril100Ids1.isEmpty || ril100Ids2.isEmpty) {
      return false;
    }

    // Check if any RIL100 ID from the first list matches any from the second list
    for (String id1 in ril100Ids1) {
      for (String id2 in ril100Ids2) {
        if (id1 == id2) {
          return true;
        }
      }
    }

    return false;
  }

  List<Marker> _buildStationMarkers(BuildContext context) {
    final journey = widget.page.journey;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Set to keep track of unique stations (by coordinates)
    final Set<String> addedStations = {};
    final List<Marker> markers = [];

    // For each leg, add origin and destination stations
    for (final leg in journey.legs) {
      // Only add transit legs (skip walking legs)
      if (leg.isWalking != true && leg.lineName != null) {
        // Add origin station if not already added
        final originKey = '${leg.origin.latitude},${leg.origin.longitude}';
        if (!addedStations.contains(originKey)) {
          addedStations.add(originKey);
          markers.add(_createStationMarker(leg.origin, colors, leg.lineColorNotifier.value));
        }

        // Add destination station if not already added
        final destinationKey = '${leg.destination.latitude},${leg.destination.longitude}';
        if (!addedStations.contains(destinationKey)) {
          addedStations.add(destinationKey);
          markers.add(_createStationMarker(leg.destination, colors, leg.lineColorNotifier.value));
        }
      }
    }

    return markers;
  }

  Widget _buildInterchangeComponent(
    BuildContext context,
    Leg arrivingLeg,
    Leg departingLeg,
    String? platformChangeText,
    bool showInterchangeTime,
  ) {
    Color arrivalTimeColor = Theme.of(context).colorScheme.onSurface;
    Color departureTimeColor = Theme.of(context).colorScheme.onPrimaryContainer;
    Color arrivalPlatformColor = Theme.of(context).colorScheme.onSurface;
    Color departurePlatformColor = Theme.of(
      context,
    ).colorScheme.onPrimaryContainer;

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

    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;
    double height = 220;
    int upperFlex = 60;
    if (!showInterchangeTime) {
      height -= 20;
      upperFlex += 8;
    }

    return Column(
      children: [
        SizedBox(
          height: height, // Reduced from 300
          child: Column(
            children: [
              Flexible(
                flex: upperFlex,
                child: Container(
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8), // Reduced from 8.0
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        color: colorScheme.surfaceContainerLowest,
                        boxShadow: [BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withAlpha(20),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    )]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          4,
                        ), // Reduced from 16
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Arrival ${arrivingLeg.effectiveArrivalFormatted}',
                              style: textTheme.titleMedium!.copyWith(
                                color: arrivalTimeColor,
                              ),
                            ),
                            if (arrivingLeg.arrivalPlatform == null)
                              Text(
                                'at the Station',
                                style: textTheme.bodySmall!.copyWith(color: colorScheme.onSurface),
                              ),
                            if (arrivingLeg.arrivalPlatform != null)
                              Text(
                                'Platform ${arrivingLeg.effectiveArrivalPlatform}',
                                style: textTheme.bodySmall!.copyWith(
                                  color: arrivalPlatformColor,
                                ),
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    color: colorScheme.surfaceContainerLowest,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ), // Reduced from 24.0
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
                                style: textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (departingLeg.departureDateTime
                                      .difference(arrivingLeg.arrivalDateTime)
                                      .inMinutes <
                                  4)
                                if (showInterchangeTime)
                                  Text(
                                    'Interchange Time: ${departingLeg.departureDateTime
                                            .difference(
                                              arrivingLeg.arrivalDateTime,
                                            )
                                            .inMinutes} min',
                                    style: textTheme.titleSmall!.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                              if (departingLeg.departureDateTime
                                      .difference(arrivingLeg.arrivalDateTime)
                                      .inMinutes >=
                                  4)
                                if (showInterchangeTime)
                                  Text(
                                    'Interchange Time: ${departingLeg.departureDateTime
                                            .difference(
                                              arrivingLeg.arrivalDateTime,
                                            )
                                            .inMinutes} min',
                                    style: textTheme.titleSmall!.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8), // Reduced from 16
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 60, // Reduced from 80
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 16,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                    color: colorScheme.primaryContainer,
                                    boxShadow: [BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withAlpha(20),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    )]
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      4,
                                      16,
                                      4,
                                    ), // Reduced from 16
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Departure ${departingLeg
                                                  .effectiveDepartureFormatted}',
                                          style: textTheme.titleMedium!
                                              .copyWith(
                                                color: departureTimeColor,
                                              ),
                                        ),
                                        if (departingLeg.departurePlatform ==
                                            null)
                                          Text(
                                            'at the Station',
                                            style: textTheme.bodyMedium!
                                                .copyWith(
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        if (departingLeg.departurePlatform !=
                                            null)
                                          Text(
                                            'Platform ${departingLeg
                                                    .effectiveDeparturePlatform}',
                                            style: textTheme.bodyMedium!
                                                .copyWith(
                                                  color: departurePlatformColor,
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
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Marker _createStationMarker(Station station, ColorScheme colors, Color? lineColor) {
    // Choose appropriate icon based on station type
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
            child: Icon(
              iconData,
              color: colors.onPrimary,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildOriginComponent(BuildContext context, Leg l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(24)),
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
                      color: Theme.of(context).colorScheme.onSurface, // Ensure good contrast
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
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          l.effectiveDepartureFormatted,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (l.departurePlatformEffective.isNotEmpty)
                          Text(
                            'Platform ${l.departurePlatformEffective}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
          borderRadius: BorderRadius.all(Radius.circular(24)),
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
                      color: Theme.of(context).colorScheme.onSurface, // Ensure good contrast
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
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          l.effectiveArrivalFormatted,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (l.arrivalPlatformEffective.isNotEmpty)
                          Text(
                            'Platform ${l.arrivalPlatformEffective}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Widget _buildWalkingLegNew(BuildContext context, Leg leg, int index, List<Leg> legs)
  {
    if (leg.distance == null || leg.distance == 0) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints)
      {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: <Widget> [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    SizedBox(width: (constraints.maxWidth / 100)* 12,),
                    Icon(Icons.directions_walk),
                    SizedBox(width: 8,),
                    Text('Walk ${leg.distance}m (${_formatLegDuration(leg.departureDateTime, leg.arrivalDateTime)})', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    Spacer(),
                    IconButton.filled(
                      onPressed: () => _focusMapOnLeg(leg),
                      icon: Icon(Icons.map),
                      color: Theme.of(context).colorScheme.tertiary,
                      style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiaryContainer),
                    ),
                  ],),
                ) 
              ),
              Positioned.fill(
                right: constraints.maxWidth / 100 * 88,
                left: constraints.maxWidth / 100 * 6,
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(radius: Radius.circular(24)),
                  child: Container(
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),),
                ),)
            ],
          ),
        );
      }
    );
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

  Widget _buildPlatformChangeText(
    BuildContext context,
    String platformChangeText,
  ) {
    final parts = platformChangeText.split(' to ');
    if (parts.length != 2) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
            parts[0], // Keep the "Platform change: X" text intact
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
                Icons.arrow_forward,
                size: 14,
                color: Theme.of(context).colorScheme.tertiary
            ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No journeys found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: _currentZoom,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags:
              InteractiveFlag.drag |
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
                _currentCenter = camera.center;
                _currentZoom = camera.zoom;
              }

              if (hasGesture && _alignPositionOnUpdate != AlignOnUpdate.never) {
                setState(
                      () => _alignPositionOnUpdate = AlignOnUpdate.never,
                );
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            // Add the polyline layer with route path
            _buildPolylineLayer(),
            MarkerLayer(markers: _buildStationMarkers(context)),
            CurrentLocationLayer(
              alignPositionStream: _alignPositionStreamController.stream,
              alignPositionOnUpdate: _alignPositionOnUpdate,
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
        _buildLocationButton(context),
      ],
    );
  }


  Widget _buildPolylineLayer() {
    // Get the colored polylines by leg
    final List<Polyline> polylines = _extractPolylinesByLeg();

    if (polylines.isEmpty) {
      print("DEBUG: No polylines created for journey legs");
      return const SizedBox.shrink();
    }

    print("DEBUG: Created ${polylines.length} polylines for journey legs");

    // Return the PolylineLayer with all our colored polylines
    return PolylineLayer(polylines: polylines);
  }

  List<LatLng> _extractRoutePointsFromLegs() {
    List<LatLng> allPoints = [];

    try {
      // Iterate through each leg to extract polyline data
      for (final leg in widget.journey.legs) {
        if (leg.polyline == null) continue;

        final dynamic polylineData = leg.polyline;

        // Parse the GeoJSON data
        final Map<String, dynamic> geoJson =
            polylineData is Map<String, dynamic>
            ? polylineData
            : jsonDecode(polylineData);

        if (geoJson['type'] == 'FeatureCollection' &&
            geoJson['features'] is List) {
          final List features = geoJson['features'];

          for (final feature in features) {
            if (feature['geometry'] != null &&
                feature['geometry']['type'] == 'Point' &&
                feature['geometry']['coordinates'] is List) {
              final List coords = feature['geometry']['coordinates'];

              // GeoJSON uses [longitude, latitude] format
              if (coords.length >= 2) {
                final double lng = coords[0] is double
                    ? coords[0]
                    : double.parse(coords[0].toString());
                final double lat = coords[1] is double
                    ? coords[1]
                    : double.parse(coords[1].toString());
                allPoints.add(LatLng(lat, lng));
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing leg polyline data: $e');
    }

    return allPoints;
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
          onTap: () {
            _centerOnUserLocation();
          },
          child: Container(
            width: 56.0,
            height: 56.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location,
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnUserLocation() {
    print("Location button pressed");
    if (_currentUserLocation != null) {
      print("Centering on location: $_currentUserLocation");

      setState(() {
        _alignPositionOnUpdate = AlignOnUpdate.always;
      });

      // Use the stream controller to trigger alignment
      _alignPositionStreamController.add(18.0);

      // Also use animatedMapMove for smooth transition
      animatedMapMove(_mapController.camera.center, _mapController.camera.zoom, _currentUserLocation!, 18.0);
    } else {
      print("Cannot center: current user location is null");
    }
  }


  // Add this as a class field
  final Map<String, Color> _transitLineColorCache = {};

  List<Polyline> _extractPolylinesByLeg() {
    List<Polyline> polylines = [];
    final Map<String, Color> modeColors = {
      'train': const Color(0xFF9C27B0), // Purple for trains
      'subway': const Color(0xFF0075BF), // Blue for subway/metro
      'tram': const Color(0xFFE4000F), // Red for trams
      'bus': const Color(0xFF9A258F), // Magenta for buses
      'ferry': const Color(0xFF0098D8), // Light blue for ferries
      'walking': Colors.grey, // Grey for walking
      'default': Colors.blue, // Default blue
    };

    try {
      for (int i = 0; i < widget.journey.legs.length; i++) {
        final leg = widget.journey.legs[i];
        if (leg.polyline == null) continue;

        final List<LatLng> legPoints = _extractPointsFromLegPolyline(
          leg.polyline,
        );
        if (legPoints.isEmpty) continue;

        // Determine color based on transit info
        Color lineColor;

        if (leg.isWalking == true) {
          lineColor = modeColors['walking']!;
        } else {
          // Create a cache key using available properties
          final String cacheKey =
              '${leg.lineName ?? ''}-${leg.productName ?? ''}';
          String productType = leg.productName?.toLowerCase() ?? 'default';

          // Use cached color if available, otherwise use product-specific color
          lineColor =
              _transitLineColorCache[cacheKey] ??
              modeColors[productType] ??
              modeColors['default']!;

          // If not in cache yet, schedule async lookup but don't wait for it
          if (!_transitLineColorCache.containsKey(cacheKey) &&
              leg.lineName != null &&
              leg.lineName!.isNotEmpty &&
              legPoints.isNotEmpty) {

                leg.lineColorNotifier.addListener((){
                  if (mounted) {
                    setState(() {
                      _transitLineColorCache[cacheKey] = leg.lineColorNotifier.value as Color;
                    });
                  }
                });

            // LatLng centerPoint = legPoints[legPoints.length ~/ 2];
            // final overpass = Overpassapi();

            // Start the async call but don't block polyline creation
            // overpass
            //     .getTransitLineColor(
            //       lat: centerPoint.latitude,
            //       lon: centerPoint.longitude,
            //       lineName: leg.lineName!,
            //       mode: leg.productName,
            //     )
            //     .then((color) {
            //       if (mounted && color != null) {
            //         setState(() {
            //           _transitLineColorCache[cacheKey] = color as Color;
            //           // The setState will trigger rebuild with the new colors
            //         });
            //       }
            //     });
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
      final Map<String, dynamic> geoJson = polylineData is Map<String, dynamic>
          ? polylineData
          : jsonDecode(polylineData);

      if (geoJson['type'] == 'FeatureCollection' &&
          geoJson['features'] is List) {
        final List features = geoJson['features'];

        for (final feature in features) {
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

class LegWidget extends StatefulWidget{
  final Leg leg;
  Color colorArg;
  final VoidCallback? onMapPressed;
  
  LegWidget({super.key, required this.leg, required this.colorArg, this.onMapPressed});
  @override
  State<LegWidget> createState() => _LegWidgetState();
}


class _LegWidgetState extends State<LegWidget> {
  bool _isExpanded = false;
  Remark? comfortCheckinRemark; 
  Remark? bicycleRemark;
  late VoidCallback _colorListener;
  Color lineColor = Colors.grey;
  Color onLineColor = Colors.black;
  

  @override
  void initState() 
  {
    super.initState();
    lineColor = widget.colorArg;
    try{
    comfortCheckinRemark = widget.leg.remarks!.firstWhere((remark) => remark.summary == 'Komfort-Checkin available');
    } catch (e) {
      comfortCheckinRemark = null;
    }
    try{
    bicycleRemark = widget.leg.remarks!.firstWhere((remark) => remark.summary == 'bicycles conveyed');
    } catch (e) {
      bicycleRemark = null;
    }
    final brightness = ThemeData.estimateBrightnessForColor(lineColor);
    onLineColor = brightness == Brightness.light 
      ? Colors.black 
      : Colors.white;

    _colorListener = () {
      if (mounted) {
        setState(() {
          lineColor = widget.leg.lineColorNotifier.value ?? Colors.grey;
          final brightness = ThemeData.estimateBrightnessForColor(lineColor);
          onLineColor = brightness == Brightness.light
              ? Colors.black
              : Colors.white;
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
                          SizedBox(width: (constraints.maxWidth / 100) * 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Line Chip
                                if (widget.leg.lineName != null && widget.leg.lineName!.isNotEmpty)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: lineColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.leg.lineName!,
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: onLineColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                // Features
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    if (comfortCheckinRemark != null)
                                      remark(context, comfortCheckinRemark!),
                                    if (bicycleRemark != null)
                                      remark(context, bicycleRemark!),
                                  ],
                                ),
                                // Further Information
                                FilledButton.tonalIcon(
                                  onPressed: () => {},
                                  label: const Text('Further Information'),
                                  icon: const Icon(Icons.chevron_right),
                                  iconAlignment: IconAlignment.end,
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(lineColor.withAlpha(120)),
                                    foregroundColor: WidgetStateProperty.all(onLineColor),
                                  ),
                                ),
                                // Stops Button
                                if (hasIntermediateStops)
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    label: Text(_isExpanded ? 'Hide Stops' : 'Show Stops'),
                                    icon: AnimatedRotation(
                                      duration: Duration(milliseconds: 200),
                                      turns: _isExpanded ? .5 : 0,
                                      child: Icon(Icons.arrow_drop_down)),
                                    iconAlignment: IconAlignment.end,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(lineColor.withAlpha(120)),
                                      foregroundColor: WidgetStateProperty.all(onLineColor),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Reserve space for the map button
                          const SizedBox(width: 80),
                        ],
                      ),
                    ),
                    // Expandable Stops List - outside the main padding
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildStopsList(context),
                      crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              // Line indicator
              Positioned.fill(
                right: constraints.maxWidth / 100 * 88,
                left: constraints.maxWidth / 100 * 6,
                child: Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 16,
                child: IconButton.filled(
                  onPressed: widget.onMapPressed,
                  icon: Icon(Icons.map),
                  color: Theme.of(context).colorScheme.tertiary,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
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
    // Filter out first and last stops
    final intermediateStops = widget.leg.stopovers.length > 2
        ? widget.leg.stopovers.sublist(1, widget.leg.stopovers.length - 1)
        : <Stopover>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: lineColor.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lineColor.withAlpha(100), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intermediateStops.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: lineColor.withAlpha(100),
              ),
              itemBuilder: (context, index) {
                final stop = intermediateStops[index];
                return _buildStopItem(context, stop);
              },
            ),
          ],
        ),
      ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onLineColor,
                  ),
                ),
              if (stopover.effectiveDepartureDateTimeLocal != null)
                Text(
                  'Dep: ${_formatTime(stopover.effectiveDepartureDateTimeLocal!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onLineColor,
                  ),
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


  Widget remark(BuildContext context, Remark remark)
  {
    Icon icon = Icon(Icons.power_off);
    switch (remark.summary) 
    {
      case 'Komfort-Checkin available':
      icon = Icon(Icons.check_circle_outline, size: 12);
      break;
      case 'bicycles conveyed':
      icon = Icon(Icons.pedal_bike_outlined, size: 12);
      break;
    }

    if (remark.summary == null || remark.summary!.isEmpty) {
      return const SizedBox.shrink();
    }

    return IntrinsicWidth(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: InkWell(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      onTap: () {
        // Your onTap action here
        print('Tapped on remark: ${remark.summary}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(children: [
            icon,
            SizedBox(width: 4),
            Text(remark.summary!, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: onLineColor),),
          ],)
        ),
      ),
        ),
      ),
    );
  }

}