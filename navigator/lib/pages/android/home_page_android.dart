import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/pages/android/connections_page_android.dart';
import 'package:navigator/pages/android/savedJourneys_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/trip.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/customWidgets/parent_child_checkboxes.dart';
import 'dart:math' as math;

class HomePageAndroid extends StatefulWidget {
  final HomePage page;

  const HomePageAndroid(this.page, {super.key});

  @override
  State<HomePageAndroid> createState() => _HomePageAndroidState();
}

class _HomePageAndroidState extends State<HomePageAndroid>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<Location> _searchResults = [];
  String _lastSearchedText = '';
  Timer? _debounce;
  LatLng? _currentUserLocation;
  LatLng _currentCenter = LatLng(52.513416, 13.412364);
  double _currentZoom = 10;
  final MapController _mapController = MapController();
  List<Polyline> _lines = [];
  List<Station> _stations = [];
  Savedjourney? ongoingJourney;
  List<Trip> tripsForOngoingJourneyLegs = [];
  List<int> legsOfOngoingJourneyThatHaveATrip = [];
  Map<int, Trip> _legIndexToTripMap = {};
  bool ongoingJourneyIntermediateStopsExpanded = false;
  bool lowerBoxExpanded = false;
  Completer<void>? ongoingJourneyMapViewCompleter;
  List<Polyline> _ongoingJourneyPolylines = [];
  final Map<String, Color> _ongoingJourneyTransitLineColorCache = {};
  int? ongoingJourneycurrentLegIndex;

  //Map Options
  bool showLightRail = true;
  bool showStationLabelsLightRail = true;
  List<Polyline> _lightRailLines = [];
  bool showSubway = true;
  bool showStationLabelsSubway = true;
  List<Polyline> _subwayLines = [];
  bool showTram = false;
  bool showStationLabelsTram = false;
  List<Polyline> _tramLines = [];
  // bool showBus = false;
  // bool showStationLabelsBus = false;
  // List<Polyline> _busLines = [];
  // bool showTrolleybus = false;
  // List<Polyline> _trolleyBusLines = [];
  bool showFerry = false;
  bool showStationLabelsFerry = true;
  List<Polyline> _ferryLines = [];
  bool showFunicular = false;
  bool showStationLabelsFunicular = false;
  List<Polyline> _funicularLines = [];
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  List<FavoriteLocation> faves = [];
  bool ongoingJourneyOnMap = false;

  @override
  void initState() {
    super.initState();
    initiateLines();
    fetchStations();

    _alignPositionOnUpdate = AlignOnUpdate.always;
    _alignPositionStreamController = StreamController<double?>();

    _controller.addListener(() {
      _onSearchChanged(_controller.text.trim());
    });

    _setInitialUserLocation();
    _initializeOngoingJourney();
    _getFaves();
  }

  Future<void> _initializeOngoingJourney() async {
    await _updateOngoingJourney();
    if (ongoingJourney != null) {
      _initializeOngoingJourneyLineColorListener();
      await _getOngoingJourneyTrips(); // This should complete before UI renders
      _updateOngoingJourneyPolylines();
    }
  }

  // Add these debug methods to help identify the issue:

  Future<void> _getOngoingJourneyTrips() async {
    if (ongoingJourney == null) {
      print('DEBUG: No ongoing journey found');
      return;
    }

    print(
      'DEBUG: Processing ${ongoingJourney!.journey.legs.length} legs for ongoing journey',
    );

    // Clear existing data
    setState(() {
      legsOfOngoingJourneyThatHaveATrip.clear();
      tripsForOngoingJourneyLegs.clear();
      _legIndexToTripMap.clear();
    });

    Map<int, Trip> legIndexToTrip = {};

    List<Leg> legs = ongoingJourney!.journey.legs;
    for (int i = 0; i < legs.length; i++) {
      Leg leg = legs[i];
      print('DEBUG: Processing leg $i/${legs.length - 1}');
      print('DEBUG: - From: ${leg.origin.name}');
      print('DEBUG: - To: ${leg.destination.name}');
      print('DEBUG: - Product: ${leg.product}');
      print('DEBUG: - Line: ${leg.lineName}');
      print('DEBUG: - TripID: ${leg.tripID}');
      print('DEBUG: - IsWalking: ${leg.isWalking}');

      // Only process non-walking legs with trip IDs
      if (leg.isWalking != true &&
          leg.tripID != null &&
          leg.tripID!.isNotEmpty) {
        print(
          'DEBUG: Attempting to fetch trip for leg $i with tripID: ${leg.tripID}',
        );

        try {
          Trip? trip = await widget.page.service.getTripFromLeg(
            leg,
            includeRemarks: true,
            includePolyline: false, // Don't need polyline for stopover display
          );

          if (trip != null) {
            print('DEBUG: Successfully fetched trip for leg $i');
            print('DEBUG: - Trip ID: ${trip.id}');
            print('DEBUG: - Trip line: ${trip.line?.name}');
            print('DEBUG: - Stopovers count: ${trip.stopovers.length}');

            // Debug stopover details
            if (trip.stopovers.isNotEmpty) {
              print(
                'DEBUG: - First stopover: ${trip.stopovers.first.station.name}',
              );
              print(
                'DEBUG: - Last stopover: ${trip.stopovers.last.station.name}',
              );

              // Print all stopovers for debugging
              for (int j = 0; j < trip.stopovers.length; j++) {
                final stopover = trip.stopovers[j];
                print(
                  'DEBUG: - Stopover $j: ${stopover.station.name} at ${stopover.plannedArrival}',
                );
              }
            } else {
              print('DEBUG: - WARNING: Trip has no stopovers!');
            }

            legIndexToTrip[i] = trip;
          } else {
            print('DEBUG: No trip returned for leg $i (API returned null)');
          }
        } catch (e) {
          print('DEBUG: Exception fetching trip for leg $i: $e');
        }
      } else {
        String reason = leg.isWalking == true ? 'walking leg' : 'no tripID';
        print('DEBUG: Skipping leg $i - $reason');
      }
    }

    print(
      'DEBUG: Successfully fetched ${legIndexToTrip.length} trips out of ${legs.length} legs',
    );

    // Update state with all the fetched data
    if (mounted) {
      // Check if widget is still mounted
      setState(() {
        legsOfOngoingJourneyThatHaveATrip = legIndexToTrip.keys.toList();
        tripsForOngoingJourneyLegs = legIndexToTrip.values.toList();
        _legIndexToTripMap = legIndexToTrip;
      });

      print(
        'DEBUG: State updated - _legIndexToTripMap has ${_legIndexToTripMap.length} entries',
      );

      // Additional debugging: print the map contents
      _legIndexToTripMap.forEach((legIndex, trip) {
        print(
          'DEBUG: Leg $legIndex -> Trip ${trip.id} with ${trip.stopovers.length} stopovers',
        );
      });
    }
  }

  void _initializeOngoingJourneyLineColorListener() {
    if (ongoingJourney != null) {
      for (Leg l in ongoingJourney!.journey.legs) {
        l.lineColorNotifier.addListener(_updateLineColor);
        l.initializeLineColor();
      }
    }
  }

  void _updateLineColor() {
  setState(() {
    _updateOngoingJourneyPolylines(); // Add this line
  });
}

  void _disposeOngoingJourneyLineColorListener() {
    if (ongoingJourney != null) {
      for (Leg l in ongoingJourney!.journey.legs) {
        l.lineColorNotifier.removeListener(_updateLineColor);
      }
    }
  }

  Future<void> _getFaves() async {
    List<FavoriteLocation> f = await Localdatasaver.getFavouriteLocations();
    setState(() {
      faves = f;
    });
  }

  Future<void> _saveFavoriteOrder(List<FavoriteLocation> reorderedFaves) async {
    try {
      // Clear all existing favorites
      for (FavoriteLocation fave in faves) {
        await Localdatasaver.removeFavouriteLocation(fave);
      }

      // Re-add them in the new order
      for (FavoriteLocation fave in reorderedFaves) {
        await Localdatasaver.addLocationToFavourites(fave.location, fave.name);
      }
    } catch (e) {
      print('Error saving favorite order: $e');
    }
  }

  Future<void> _updateOngoingJourney() async {
    List<Savedjourney> journeys = await Localdatasaver.getSavedJourneys();
    bool found = false;
    for (Savedjourney sj in journeys) {
      if (found) {
        break;
      }
      if (DateTime.now().isAfter(sj.journey.plannedDepartureTime) &&
          DateTime.now().isBefore(sj.journey.arrivalTime)) {
        Savedjourney j = sj;
        Savedjourney newJ = Savedjourney(
          journey: await widget.page.service.refreshJourneyByToken(
            j.journey.refreshToken,
          ),
          id: Localdatasaver.calculateJourneyID(j.journey),
        );
        setState(() {
          ongoingJourney = newJ;
        });
        found = true;
      }
    }
  }

  void _updateOngoingJourneyPolylines() {
  if (mounted) {
    setState(() {
      _ongoingJourneyPolylines = _extractOngoingJourneyPolylines();
    });
  }
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
            feature['geometry']['type'] == 'Point' &&  // This is correct for your API
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

  List<Polyline> _extractOngoingJourneyPolylines() {
  if (ongoingJourney == null) return [];
  
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
    for (int i = 0; i < ongoingJourney!.journey.legs.length; i++) {
      final leg = ongoingJourney!.journey.legs[i];
      if (leg.polyline == null) continue;

      final List<LatLng> legPoints = _extractPointsFromLegPolyline(leg.polyline);
      if (legPoints.isEmpty) continue;

      // Determine color based on transit info
      Color lineColor;

      if (leg.isWalking == true) {
        lineColor = modeColors['walking']!;
      } else {
        // Create a cache key using available properties
        final String cacheKey = '${leg.lineName ?? ''}-${leg.productName ?? ''}';
        String productType = leg.productName?.toLowerCase() ?? 'default';

        // Use cached color if available, otherwise use product-specific color
        lineColor = _ongoingJourneyTransitLineColorCache[cacheKey] ??
            leg.lineColorNotifier.value ??
            modeColors[productType] ??
            modeColors['default']!;

        // Listen for color updates if not cached
        if (!_ongoingJourneyTransitLineColorCache.containsKey(cacheKey)) {
          leg.lineColorNotifier.addListener(() {
            if (mounted && leg.lineColorNotifier.value != null) {
              setState(() {
                _ongoingJourneyTransitLineColorCache[cacheKey] = leg.lineColorNotifier.value!;
              });
            }
          });
        }
      }

      double strokeWidth = leg.isWalking == true ? 1.0 : 3.0; // Slightly thicker for visibility
      
      if(ongoingJourneycurrentLegIndex != null && ongoingJourneycurrentLegIndex == i)
      {
        strokeWidth = strokeWidth * 2;
      }

      polylines.add(
        Polyline(
          borderColor: Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black,
          borderStrokeWidth: 5,
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
    print('Error creating ongoing journey polylines: $e');
  }

  return polylines;
}

  // Helper function to get minimum zoom level for different station types
  double _getMinZoomForStation(Station station) {
    // National and national express stations - show earliest (lowest zoom)
    if (station.national || station.nationalExpress) {
      return 9.5;
    }

    // Regional stations - show at medium zoom
    if (station.regional || station.regionalExpress) {
      return 10.5;
    }

    // Local transport - show at higher zoom levels
    if (station.suburban || station.subway) {
      return 12.5;
    }

    // Tram, ferry, etc. - show at highest zoom
    if (station.tram || station.ferry || station.bus || station.taxi) {
      return 14.5;
    }

    // Default fallback
    return 16.5;
  }

  // Helper function to get the appropriate show labels boolean
  bool _getShowLabels(String transportType) {
    switch (transportType) {
      case 'lightRail':
        return showStationLabelsLightRail;
      case 'subway':
        return showStationLabelsSubway;
      case 'tram':
        return showStationLabelsTram;
      case 'ferry':
        return showStationLabelsFerry;
      case 'funicular':
        return showStationLabelsFunicular;
      default:
        return false;
    }
  }

  // Helper function to filter stations by transport type
  bool _shouldShowStation(Station station, String transportType) {
    // Always show stations of these types regardless of transport type
    if (station.national ||
        station.nationalExpress ||
        station.regional ||
        station.regionalExpress) {
      return true;
    }

    switch (transportType) {
      case 'lightRail':
        return station.suburban;
      case 'subway':
        return station.subway;
      case 'tram':
        return station.tram;
      case 'ferry':
        return station.ferry;
      case 'funicular':
        return false; // No funicular property in Station class
      default:
        return false;
    }
  }

  // Function to create marker layer for a specific transport type
  MarkerLayer? _createMarkerLayer(String transportType) {
    if (!_getShowLabels(transportType) || _currentZoom <= 12) return null;
    ColorScheme colors = Theme.of(context).colorScheme;

    return MarkerLayer(
      markers: _stations
          .where((station) {
            // Filter by transportation type settings first
            if (!_shouldShowStation(station, transportType)) {
              return false;
            }

            // Filter stations based on zoom level and station importance
            final minZoom = _getMinZoomForStation(station);
            if (_currentZoom < minZoom) return false;

            // At higher zoom levels, show all stations
            return true;
          })
          // Group by name and take only the first station of each name when zoomed out
          .fold<Map<String, Station>>({}, (map, station) {
            if (_currentZoom <= 15.5 && !map.containsKey(station.name)) {
              map[station.name] = station;
            } else if (_currentZoom > 15.5) {
              // When zoomed in, show all stations individually
              map["${station.name}_${station.latitude}_${station.longitude}"] =
                  station;
            }
            return map;
          })
          .values
          // Apply collision detection for labels when zoomed in, but not at extreme zoom
          .fold<Map<String, List<Station>>>({}, (collisionMap, station) {
            if (_currentZoom > 16.5) {
              // At very high zoom levels, bypass collision detection completely
              // Each station gets its own unique key to ensure all are shown
              final uniqueKey =
                  "${station.name}_${station.latitude}_${station.longitude}";
              collisionMap[uniqueKey] = [station];
            } else {
              // Normal collision detection at moderate zoom levels
              final key = _getLabelCollisionKey(station, _currentZoom);
              if (!collisionMap.containsKey(key)) {
                collisionMap[key] = [];
              }
              collisionMap[key]!.add(station);
            }
            return collisionMap;
          })
          .entries
          .expand((entry) {
            final stations = entry.value;
            // If multiple stations share the same collision key, only keep one instance of each name
            // but only apply this logic at lower zoom levels
            if (stations.length > 1 && _currentZoom <= 17) {
              final uniqueByName = <String, Station>{};
              for (final station in stations) {
                uniqueByName[station.name] = station;
              }
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
                  // Only show the label text when zoomed in close enough
                  if (_currentZoom > 15.5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                  if (_currentZoom > 14.5) const SizedBox(height: 2),
                  Container(
                    decoration: BoxDecoration(
                      // Scale marker size based on zoom level
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
                    padding: EdgeInsets.all(_currentZoom > 14 ? 4 : 3),
                    child: Icon(
                      _getTransportIcon(station),
                      color: colors.onPrimary,
                      size: _currentZoom > 14 ? 14 : 12,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  Future<void> initiateLines() async {
    await widget.page.service.refreshPolylines();
    if (widget.page.service.loadedSubwayLines.isNotEmpty) {
      setState(() {
        _lines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty,
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60),
                // Use the actual line color!
              ),
            )
            .toList();
        _subwayLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) =>
                  subwayLine.points.isNotEmpty && subwayLine.type == 'subway',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60),
                // Use the actual line color!
              ),
            )
            .toList();
        _lightRailLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) =>
                  subwayLine.points.isNotEmpty &&
                  subwayLine.type == 'light_rail',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60),
                // Use the actual line color!
              ),
            )
            .toList();
        _tramLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) =>
                  subwayLine.points.isNotEmpty && subwayLine.type == 'tram',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60),
                // Use the actual line color!
              ),
            )
            .toList();
        // _busLines = widget.page.service.loadedSubwayLines
        // .where(
        //   (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'bus',
        // ) // prevent empty lines
        // .map(
        //   (subwayLine) => Polyline(
        //     points: subwayLine.points,
        //     strokeWidth: 1.0,
        //     color: subwayLine.color,
        //     borderColor: subwayLine.color.withAlpha(60)
        //     // Use the actual line color!
        //   ),
        // )
        // .toList();
        // _trolleyBusLines = widget.page.service.loadedSubwayLines
        // .where(
        //   (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'trolleybus',
        // ) // prevent empty lines
        // .map(
        //   (subwayLine) => Polyline(
        //     points: subwayLine.points,
        //     strokeWidth: 1.0,
        //     color: subwayLine.color,
        //     borderColor: subwayLine.color.withAlpha(60)
        //     // Use the actual line color!
        //   ),
        // )
        // .toList();
        _ferryLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) =>
                  subwayLine.points.isNotEmpty && subwayLine.type == 'ferry',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 1.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60),
                // Use the actual line color!
              ),
            )
            .toList();
        _funicularLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) =>
                  subwayLine.points.isNotEmpty &&
                  subwayLine.type == 'funicular',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60),
                // Use the actual line color!
              ),
            )
            .toList();
      });
    }
  }

  Future<void> fetchStations() async {
    final location = await widget.page.service.getCurrentLocation();

    if (location.latitude != 0 && location.longitude != 0) {
      try {
        final transportTypes = ['subway', 'light_rail', 'tram'];
        final fetchedStations = await widget.page.service.overpass
            .fetchStationsByType(
              lat: location.latitude,
              lon: location.longitude,
              radius: 50000,
            );

        setState(() {
          _stations = fetchedStations;
        });
      } catch (e) {
        print('Error fetching stations: $e');
      }
    }
  }

  String _getLabelCollisionKey(Station station, double zoom) {
    // Adjust the grid size based on zoom level
    double gridSize = 100; // pixels

    if (zoom > 16.5) {
      gridSize = 150;
    } else if (zoom > 15.5) {
      gridSize = 120;
    }

    // Convert lat/lng to a rough grid position
    // This is a simplification that works for collision detection
    final gridX = (station.latitude * 1000 / gridSize).round();
    final gridY = (station.longitude * 1000 / gridSize).round();

    return "$gridX:$gridY";
  }

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _currentCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _currentCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: _currentZoom, end: destZoom);

    var controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _setInitialUserLocation() async {
    final loc = await widget.page.service.getCurrentLocation();

    if (loc.latitude != 0 && loc.longitude != 0) {
      final newCenter = LatLng(loc.latitude, loc.longitude);
      setState(() {
        _currentUserLocation = newCenter;
      });

      animatedMapMove(newCenter, 12.0);
      fetchStations();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query != _lastSearchedText) {
        getSearchResults(query);
        _lastSearchedText = query;
      }
    });
  }

  Future<void> getSearchResults(String query) async {
    final results = await widget.page.getLocations(query); // async method
    setState(() {
      _searchResults = results;
    });
  }

  IconData _getTransportIcon(Station station) {
    if (station.subway) return Icons.subway;
    if (station.tram) return Icons.tram;
    if (station.suburban) return Icons.directions_subway;
    if (station.national || station.nationalExpress) return Icons.train;
    if (station.regional || station.regionalExpress)
      return Icons.directions_railway;
    if (station.ferry) return Icons.directions_ferry;
    if (station.bus) return Icons.directions_bus;
    return Icons.location_on;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _alignPositionStreamController.close();
    _disposeOngoingJourneyLineColorListener();
    if (ongoingJourney != null) {
    for (final leg in ongoingJourney!.journey.legs) {
      leg.lineColorNotifier.removeListener(() {});
    }
  }
    super.dispose();
  }

  List<MarkerLayer> _buildMarkerLayers() {
    final layers = <MarkerLayer>[];

    if (showLightRail) {
      final layer = _createMarkerLayer('lightRail');
      if (layer != null) layers.add(layer);
    }

    if (showSubway) {
      final layer = _createMarkerLayer('subway');
      if (layer != null) layers.add(layer);
    }

    if (showTram) {
      final layer = _createMarkerLayer('tram');
      if (layer != null) layers.add(layer);
    }

    if (showFerry) {
      final layer = _createMarkerLayer('ferry');
      if (layer != null) layers.add(layer);
    }

    if (showFunicular) {
      final layer = _createMarkerLayer('funicular');
      if (layer != null) layers.add(layer);
    }

    return layers;
  }


@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasResults = _searchResults.isNotEmpty;
    const bottomSheetHeight = 96.0;

    return WillPopScope(
      onWillPop: () async {
        if (hasResults) {
          // clear the search and go back to the map
          setState(() {
            _searchResults.clear();
            _lastSearchedText = '';
            _controller.clear();
          });
          return false; // prevent actual pop
        }
        return true; // allow actual back navigation if no results
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
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          bottomSheetHeight + 16,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, i) {
                          final r = _searchResults[i];
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
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentUserLocation ?? _currentCenter,
                        initialZoom: _currentZoom,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: InteractionOptions(
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
                          if (hasGesture &&
                              _alignPositionOnUpdate != AlignOnUpdate.never) {
                            setState(
                              () =>
                                  _alignPositionOnUpdate = AlignOnUpdate.never,
                            );
                          }
                          // Update current zoom level
                          setState(() {
                            _currentZoom = camera.zoom;
                            _currentCenter = camera.center;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),

                        // Move all polyline layers here, before the location layers
                        if (showSubway) PolylineLayer(polylines: _subwayLines),
                        if (showLightRail)
                          PolylineLayer(polylines: _lightRailLines),
                        if (showTram) PolylineLayer(polylines: _tramLines),
                        if (showFerry) PolylineLayer(polylines: _ferryLines),
                        if (showFunicular)
                          PolylineLayer(polylines: _funicularLines),

                        if (ongoingJourney != null && _ongoingJourneyPolylines.isNotEmpty)
                          PolylineLayer(polylines: _ongoingJourneyPolylines),


                        CurrentLocationLayer(
                          alignPositionStream:
                              _alignPositionStreamController.stream,
                          alignPositionOnUpdate: _alignPositionOnUpdate,
                          style: LocationMarkerStyle(
                            marker: DefaultLocationMarker(
                              color: Colors.lightBlue[800]!,
                            ),
                            markerSize: const Size(20, 20),
                            markerDirection: MarkerDirection.heading,
                            accuracyCircleColor: Colors.blue[200]!.withAlpha(
                              0x20,
                            ),
                            headingSectorColor: Colors.blue[400]!.withAlpha(
                              0x90,
                            ),
                            headingSectorRadius: 60,
                          ),
                        ),
                        ..._buildMarkerLayers(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 20.0,
                              bottom: 160.0,
                            ),
                            child: FloatingActionButton(
                              shape: const CircleBorder(),
                              onPressed: () {
                                setState(
                                  () => _alignPositionOnUpdate =
                                      AlignOnUpdate.always,
                                );
                                _alignPositionStreamController.add(18);
                              },
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
            if (ongoingJourney != null)
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onSearchChanged,
                        style: TextStyle(color: colors.onPrimaryContainer),
                        decoration: InputDecoration(
                          hintText: 'Where do you want to go?',
                          prefixIcon: Icon(
                            Icons.location_pin,
                            color: colors.primary,
                          ),
                          filled: true,
                          fillColor: colors.primaryContainer,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        showModalBottomSheet(
                          useSafeArea: true,
                          sheetAnimationStyle: AnimationStyle(
                            curve: Curves.elasticOut,
                            duration: Duration(milliseconds: 400),
                          ),
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (BuildContext context, StateSetter setModalState) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        // Handle bar
                                        Container(
                                          width: 40,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
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
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ),
                                        Flexible(
                                          child: ListView(
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            children: [
                                              Divider(),

                                              ParentChildCheckboxes(
                                                textColor: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                activeColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                parentLabel: 'S-Bahn',
                                                initialParentValue:
                                                    showLightRail &&
                                                    showStationLabelsLightRail,
                                                childrenLabels: [
                                                  'Lines(S-Bahn)',
                                                  'Station Labels(S-Bahn)',
                                                ],
                                                initialChildrenValues: [
                                                  showLightRail,
                                                  showStationLabelsLightRail,
                                                ],
                                                onSelectionChanged: (p0, p1) {
                                                  setModalState(() {
                                                    showLightRail = p1[0];
                                                    showStationLabelsLightRail =
                                                        p1[1];
                                                  });
                                                  setState(() {
                                                    showLightRail = p1[0];
                                                    showStationLabelsLightRail =
                                                        p1[1];
                                                  });
                                                },
                                              ),

                                              Divider(),

                                              ParentChildCheckboxes(
                                                textColor: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                activeColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                parentLabel: 'U-Bahn',
                                                initialParentValue:
                                                    showSubway &&
                                                    showStationLabelsSubway,
                                                childrenLabels: [
                                                  'Lines(U-Bahn)',
                                                  'Station Labels(U-Bahn)',
                                                ],
                                                initialChildrenValues: [
                                                  showSubway,
                                                  showStationLabelsSubway,
                                                ],
                                                onSelectionChanged: (p0, p1) {
                                                  setModalState(() {
                                                    showSubway = p1[0];
                                                    showStationLabelsSubway =
                                                        p1[1];
                                                  });
                                                  setState(() {
                                                    showSubway = p1[0];
                                                    showStationLabelsSubway =
                                                        p1[1];
                                                  });
                                                },
                                              ),

                                              Divider(),

                                              ParentChildCheckboxes(
                                                textColor: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                activeColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                parentLabel: 'Tram',
                                                initialParentValue:
                                                    showTram &&
                                                    showStationLabelsTram,
                                                childrenLabels: [
                                                  'Lines(Tram)',
                                                  'Station Labels(Tram)',
                                                ],
                                                initialChildrenValues: [
                                                  showTram,
                                                  showStationLabelsTram,
                                                ],
                                                onSelectionChanged: (p0, p1) {
                                                  setModalState(() {
                                                    showTram = p1[0];
                                                    showStationLabelsTram =
                                                        p1[1];
                                                  });
                                                  setState(() {
                                                    showTram = p1[0];
                                                    showStationLabelsTram =
                                                        p1[1];
                                                  });
                                                },
                                              ),

                                              Divider(),

                                              ParentChildCheckboxes(
                                                textColor: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                activeColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                parentLabel: 'Ferry',
                                                initialParentValue:
                                                    showFerry &&
                                                    showStationLabelsFerry,
                                                childrenLabels: [
                                                  'Lines(Ferry)',
                                                  'Station Labels(Ferry)',
                                                ],
                                                initialChildrenValues: [
                                                  showFerry,
                                                  showStationLabelsFerry,
                                                ],
                                                onSelectionChanged: (p0, p1) {
                                                  setModalState(() {
                                                    showFerry = p1[0];
                                                    showStationLabelsFerry =
                                                        p1[1];
                                                  });
                                                  setState(() {
                                                    showFerry = p1[0];
                                                    showStationLabelsFerry =
                                                        p1[1];
                                                  });
                                                },
                                              ),

                                              Divider(),

                                              ParentChildCheckboxes(
                                                textColor: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                activeColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                parentLabel: 'Funicular',
                                                initialParentValue:
                                                    showFunicular &&
                                                    showStationLabelsFunicular,
                                                childrenLabels: [
                                                  'Lines(Funicular)',
                                                  'Station Labels(Funicular)',
                                                ],
                                                initialChildrenValues: [
                                                  showFunicular,
                                                  showStationLabelsFunicular,
                                                ],
                                                onSelectionChanged: (p0, p1) {
                                                  setModalState(() {
                                                    showFunicular = p1[0];
                                                    showStationLabelsFunicular =
                                                        p1[1];
                                                  });
                                                  setState(() {
                                                    showFunicular = p1[0];
                                                    showStationLabelsFunicular =
                                                        p1[1];
                                                  });
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
                      },
                      icon: Icon(Icons.settings),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildFaves(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingJourney(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme texts = Theme.of(context).textTheme;
    int situationUpperBox =
        0; // 0 = Waiting at station | 1 = on Transport | 2 Walking
    int situationLowerBox =
        0; // 0 = Take some form of transportation | 1 = Get off at | 2 = Walk somewhere | 3 = Arrival
    bool isWalkingInterchange =
        false; // Whether interchange requires walking within same station complex

    int leg = 0;
    bool afterArrival = false;

    // Find current leg
    for (int i = 0; i < ongoingJourney!.journey.legs.length; i++) {
      Leg l = ongoingJourney!.journey.legs[i];
      if (DateTime.now().isAfter(l.plannedDepartureDateTime)) {
        afterArrival = false;
        leg = i;
      }
      if (DateTime.now().isAfter(l.plannedArrivalDateTime)) {
        afterArrival = true;
      }
    }

    ongoingJourneycurrentLegIndex = leg;

    if (!afterArrival) {
      // Currently on a leg
      if (ongoingJourney!.journey.legs[leg].isWalking == true) {
        situationUpperBox = 2; // Walking
        if (leg == ongoingJourney!.journey.legs.length - 1) {
          situationLowerBox = 3; // Arrival
        } else {
          situationLowerBox = 0; // Take some form of transportation
        }
      } else {
        situationUpperBox = 1; // On Transport
        situationLowerBox = 1; // Get off at
      }

      isWalkingInterchange = false;
    } else {
      // We've arrived at the destination of the current leg
      if (leg == ongoingJourney!.journey.legs.length - 1) {
        // Final destination
        situationUpperBox = 0; // Waiting at station (arrived)
        situationLowerBox = 3; // Arrival
        isWalkingInterchange = false;
      } else {
        // At an interchange
        situationUpperBox = 0; // Waiting at station

        // Find the next actual leg (skip same-station interchanges)
        int nextActualLegIndex = leg + 1;
        while (nextActualLegIndex < ongoingJourney!.journey.legs.length) {
          final nextLeg = ongoingJourney!.journey.legs[nextActualLegIndex];

          // Skip legs that are same-station interchanges
          bool isSameStationInterchange =
              nextLeg.origin.id == nextLeg.destination.id &&
              nextLeg.origin.name == nextLeg.destination.name;

          if (!isSameStationInterchange) {
            break;
          }
          nextActualLegIndex++;
        }

        if (nextActualLegIndex < ongoingJourney!.journey.legs.length) {
          final currentLeg = ongoingJourney!.journey.legs[leg];
          final nextLeg = ongoingJourney!.journey.legs[nextActualLegIndex];

          // Check if this is a walking interchange
          isWalkingInterchange = false;

          // Case 1: There are same-station interchange legs between current and next
          if (nextActualLegIndex - leg > 1) {
            for (
              int interchangeIndex = leg + 1;
              interchangeIndex < nextActualLegIndex;
              interchangeIndex++
            ) {
              final interchangeLeg =
                  ongoingJourney!.journey.legs[interchangeIndex];

              if (interchangeLeg.origin.id == interchangeLeg.destination.id &&
                  interchangeLeg.origin.name ==
                      interchangeLeg.destination.name) {
                isWalkingInterchange = true;
                break;
              }
            }
          }

          // Case 2: Next leg is walking within station complex
          if (nextLeg.isWalking == true &&
              nextLeg.origin.ril100Ids.isNotEmpty &&
              nextLeg.destination.ril100Ids.isNotEmpty &&
              _haveSameRil100Station(
                nextLeg.origin.ril100Ids,
                nextLeg.destination.ril100Ids,
              )) {
            isWalkingInterchange = true;
          }

          // Case 3: Current and next leg are in same station complex but different platforms
          if (currentLeg.destination.ril100Ids.isNotEmpty &&
              nextLeg.origin.ril100Ids.isNotEmpty &&
              _haveSameRil100Station(
                currentLeg.destination.ril100Ids,
                nextLeg.origin.ril100Ids,
              )) {
            isWalkingInterchange = true;
          }

          // Set next action
          if (nextLeg.isWalking == true) {
            situationLowerBox = 2; // Walk somewhere
          } else {
            situationLowerBox = 0; // Take some form of transportation
          }
        } else {
          // No more legs
          situationLowerBox = 3; // Arrival
          isWalkingInterchange = false;
        }
      }
    }

    // Helper method (already exists in your code)

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
                  child: Text(
                    'at station',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ongoingJourney!.journey.legs[leg].destination.name,
                    style: texts.headlineMedium!.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 1:
        Color lineColor =
            ongoingJourney!.journey.legs[leg].lineColorNotifier.value ??
            Colors.grey;
        Color onLineColor =
            ThemeData.estimateBrightnessForColor(lineColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

        // Get the trip for this leg with better error handling
        Trip? t = _legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival =
                ongoingJourney!.journey.legs[leg].arrivalDateTime;

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
                    'on the ${ongoingJourney!.journey.legs[leg].product}',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    if (ongoingJourney!.journey.legs[leg].lineName != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: lineColor,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Text(
                            ongoingJourney!.journey.legs[leg].lineName!,
                            style: texts.labelMedium!.copyWith(
                              color: onLineColor,
                            ),
                          ),
                        ),
                      ),
                    if (ongoingJourney!.journey.legs[leg].direction != null)
                      SizedBox(width: 8),
                    if (ongoingJourney!.journey.legs[leg].direction != null)
                      Text(
                        ongoingJourney!.journey.legs[leg].direction!,
                        style: texts.titleLarge!.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),

                if (t == null)
                  Text(
                    'Loading trip details...',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  )
                else if (t.stopovers.isEmpty)
                  Text(
                    'No stops on this line',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  )
                else
                  GestureDetector(
  onTap: () {
    setState(() {
      ongoingJourneyIntermediateStopsExpanded =
          !ongoingJourneyIntermediateStopsExpanded;
    });
  },
  child: AnimatedContainer(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOutCubic,
    decoration: BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header (always visible)
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 16,
          ),
          child: Row(
            children: [
              Text(
                'Show Intermediate Stops',
                style: texts.titleMedium!.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
                  child: Row(
                    children: [
                      Text(
                        '${stopsBeforeInterchange.length}',
                        style: texts.labelMedium!.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                      AnimatedRotation(
                        turns: ongoingJourneyIntermediateStopsExpanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Animated expandable content
        ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            height: ongoingJourneyIntermediateStopsExpanded ? 300.0 : 0,
            child: ongoingJourneyIntermediateStopsExpanded 
                ? SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      bottom: 16.0, // Extra padding at bottom for better scrolling
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...stopsBeforeInterchange.map((s) {
                          String timeText = _generateStopoverTimeText(s);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.tertiaryContainer,
                              ),
                              onPressed: () {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.station.name,
                                      style: texts.titleMedium!.copyWith(
                                        color: colors.onTertiaryContainer,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          timeText,
                                          style: texts.titleMedium!.copyWith(
                                            color: colors.onTertiaryContainer,
                                          ),
                                        ),
                                        if (s.arrivalPlatform != null)
                                          Text(
                                            'Platform ${s.arrivalPlatform!}',
                                            style: texts.bodyMedium!.copyWith(
                                              color: colors.onTertiaryContainer,
                                            ),
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
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.tertiary,
                              ),
                              onPressed: () {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stopsAfterInterchange.first.station.name,
                                      style: texts.titleMedium!.copyWith(
                                        color: colors.onTertiary,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          _generateStopoverTimeText(stopsAfterInterchange.first),
                                          style: texts.titleMedium!.copyWith(
                                            color: colors.onTertiary,
                                          ),
                                        ),
                                        if (stopsAfterInterchange.first.arrivalPlatform != null)
                                          Text(
                                            'Platform ${stopsAfterInterchange.first.arrivalPlatform}',
                                            style: texts.bodyMedium!.copyWith(
                                              color: colors.onTertiary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        ...stopsAfterInterchange.skip(1).map((s) {
                          String timeText = _generateStopoverTimeText(s);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: OutlinedButton(
                              onPressed: () {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.station.name,
                                      style: texts.titleMedium!.copyWith(
                                        color: colors.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          timeText,
                                          style: texts.titleMedium!.copyWith(
                                            color: colors.onPrimaryContainer,
                                          ),
                                        ),
                                        if (s.arrivalPlatform != null)
                                          Text(
                                            'Platform ${s.arrivalPlatform!}',
                                            style: texts.bodyMedium!.copyWith(
                                              color: colors.onPrimaryContainer,
                                            ),
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
                : SizedBox.shrink(),
          ),
        ),
      ],
    ),
  ),
)
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
                    'Walk ${ongoingJourney!.journey.legs[leg].distance}m (${ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(ongoingJourney!.journey.legs[leg].departureDateTime).inMinutes} minutes) towards',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimary),
                  ),
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ongoingJourney!.journey.legs[leg].destination.name,
                    style: texts.titleLarge!.copyWith(color: colors.onPrimary),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryContainer,
                  ),
                  onPressed: () {
                    _focusMapOnLeg(ongoingJourney!.journey.legs[leg]);
                  },
                  label: Text(
                    'Focus on Map',
                    style: texts.bodyMedium!.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  icon: Icon(
                    Icons.map_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        );
    }

    switch (situationLowerBox) {
      case 0:
      Color lineColor =
            ongoingJourney!.journey.legs[leg+1].lineColorNotifier.value ??
            Colors.grey;
        Color onLineColor =
            ThemeData.estimateBrightnessForColor(lineColor) == Brightness.dark
            ? Colors.white
            : Colors.black;


        lowerBox = Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: lowerBoxExpanded ? BorderRadius.circular(24) :BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
          ),
          child: Padding(padding: EdgeInsetsGeometry.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Take the ${ongoingJourney!.journey.legs[leg + 1].product}', style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer), overflow: TextOverflow.ellipsis, maxLines: 2,),
                          SizedBox(height: 4),
                                      Row(
  children: [
    if (ongoingJourney!.journey.legs[leg + 1].lineName != null)
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: lineColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          child: Text(
            ongoingJourney!.journey.legs[leg + 1].lineName!,
            style: texts.labelMedium!.copyWith(
              color: onLineColor,
            ),
          ),
        ),
      ),
    if (ongoingJourney!.journey.legs[leg +1].direction != null)
      SizedBox(width: 8),
    if (ongoingJourney!.journey.legs[leg + 1].direction != null)
      Flexible(  // Add this wrapper
        child: Text(
          ongoingJourney!.journey.legs[leg + 1].direction!,
          style: texts.titleLarge!.copyWith(
            color: colors.onPrimaryContainer,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
  ],
),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(24)
                      ),
                      child: Padding(
                        padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
                        child: 
                          Column(
                            children: [
                              Text(prettyPrintTime(ongoingJourney!.journey.legs[leg + 1].departureDateTime), style: texts.titleMedium!.copyWith(color: colors.onTertiaryContainer)),
                              if (ongoingJourney!.journey.legs[leg+1].arrivalPlatform != null)
                                          Text(
                                            'Platform ${ongoingJourney!.journey.legs[leg+1].arrivalPlatform!}',
                                            style: texts.bodyMedium!.copyWith(
                                              color: colors.onTertiaryContainer,
                                            ),
                                          ),
                            ],
                          )
                        )
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        break;
      case 1:
      Trip? t = _legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival =
                ongoingJourney!.journey.legs[leg].arrivalDateTime;

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


        lowerBox = lowerBox = Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
          ),
          child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get off in ${ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(DateTime.now()).inMinutes} minutes(${stopsBeforeInterchange.length + 1} stops) at', style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer)),
                        SizedBox(height: 4),
                        Text(ongoingJourney!.journey.legs[leg].destination.name, style: texts.titleLarge!.copyWith(color: colors.onPrimaryContainer))
                
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Padding(
                        padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
                        child: 
                          Column(
                            children: [
                              Text(prettyPrintTime(ongoingJourney!.journey.legs[leg].arrivalDateTime), style: texts.titleMedium!.copyWith(color: colors.onTertiaryContainer)),
                              if (ongoingJourney!.journey.legs[leg].arrivalPlatform != null)
                                          Text(
                                            'Platform ${ongoingJourney!.journey.legs[leg].arrivalPlatform!}',
                                            style: texts.bodyMedium!.copyWith(
                                              color: colors.onTertiaryContainer,
                                            ),
                                          ),
                            ],
                          )
                        )
                    )
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
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                    'Walk ${ongoingJourney!.journey.legs[leg + 1].distance}m (${ongoingJourney!.journey.legs[leg + 1].arrivalDateTime.difference(ongoingJourney!.journey.legs[leg + 1].departureDateTime).inMinutes} minutes) towards',
                    style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ongoingJourney!.journey.legs[leg + 1].destination.name,
                    style: texts.titleLarge!.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                  ),
                  onPressed: () {
                    _focusMapOnLeg(ongoingJourney!.journey.legs[leg + 1]);
                  },
                  label: Text(
                    'Focus on Map',
                    style: texts.bodyMedium!.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                  icon: Icon(
                    Icons.map_outlined,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 3:
        Trip? t = _legIndexToTripMap[leg];

        List<Stopover> stopsBeforeCurrentPosition = [];
        List<Stopover> stopsBeforeInterchange = [];
        List<Stopover> stopsAfterInterchange = [];

        if (t != null && t.stopovers.isNotEmpty) {
          for (Stopover s in t.stopovers) {
            DateTime? arrivalTime = s.effectiveArrivalDateTimeLocal;
            DateTime now = DateTime.now();
            DateTime legArrival =
                ongoingJourney!.journey.legs[leg].arrivalDateTime;

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
                borderRadius: BorderRadius.circular(24)
              ),
              child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Arrive in ${ongoingJourney!.journey.legs[leg].arrivalDateTime.difference(DateTime.now()).inMinutes} minutes at', style: texts.bodyMedium!.copyWith(color: colors.onPrimaryContainer)),
                              SizedBox(height: 4),
                              Text(ongoingJourney!.journey.legs[leg].destination.name, style: texts.titleLarge!.copyWith(color: colors.onPrimaryContainer), overflow: TextOverflow.ellipsis, maxLines: 2,)
                                              
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
                            child: 
                              Column(
                                children: [
                                  Text(prettyPrintTime(ongoingJourney!.journey.legs[leg].arrivalDateTime), style: texts.titleMedium!.copyWith(color: colors.onTertiaryContainer)),
                                  if (ongoingJourney!.journey.legs[leg].arrivalPlatform != null)
                                              Text(
                                                'Platform ${ongoingJourney!.journey.legs[leg].arrivalPlatform!}',
                                                style: texts.bodyMedium!.copyWith(
                                                  color: colors.onTertiaryContainer,
                                                ),
                                              ),
                                ],
                              )
                            )
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8,)
          ],
        );
    }

    return AnimatedSize(
  duration: Duration(milliseconds: 700),
  curve: Curves.easeInOut,
  child: AnimatedContainer(
    width: double.infinity,
    duration: Duration(milliseconds: 700),
    curve: Curves.easeInOut,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(100),
          spreadRadius: 0,
          blurRadius: 16,
          offset: Offset(0, 2),
        ),
      ],
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      color: colors.surfaceContainerLowest,
    ),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(height: 8),
            Text(
              'ongoing Journey',
              style: texts.titleSmall!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8),
            upperBox,
            SizedBox(height: 8),
            lowerBox,
          ],
        ),
      ),
    ),
  ),
);
  }

  String prettyPrintTime(DateTime time) {
    String hour = '${time.hour}'.padLeft(2, '0');
    String minute = '${time.minute}'.padLeft(2, '0');
    return '$hour:$minute';
  }

  String _generateStopoverTimeText(Stopover s)
  {
    String timeText = '';
                                                if (s.arrivalDateTime != null &&
                                                    s.departureDateTime != null) {
                                                  if (s.arrivalDateTime!.hour ==
                                                          s.departureDateTime!.hour &&
                                                      s.arrivalDateTime!.minute ==
                                                          s.departureDateTime!.minute) {
                                                    timeText = prettyPrintTime(
                                                      s.arrivalDateTimeLocal!,
                                                    );
                                                  } else {
                                                    timeText =
                                                        '${prettyPrintTime(s.arrivalDateTimeLocal!)} - ${prettyPrintTime(s.departureDateTimeLocal!)}';
                                                  }
                                                }
                                                else
                                                {
                                                  if(s.arrivalDateTime == null)
                                                  {
                                                    timeText = prettyPrintTime(s.departureDateTimeLocal!);
                                                  }
                                                  else
                                                  {
                                                    timeText = prettyPrintTime(s.arrivalDateTimeLocal!);
                                                  }
                                                }
                                                return timeText;
  }

  bool _haveSameRil100Station(
    List<String> ril100Ids1,
    List<String> ril100Ids2,
  ) {
    if (ril100Ids1.isEmpty || ril100Ids2.isEmpty) {
      return false;
    }

    for (String id1 in ril100Ids1) {
      for (String id2 in ril100Ids2) {
        if (id1 == id2) {
          return true;
        }
      }
    }

    return false;
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

  Widget _buildFaves(BuildContext context) {
    return Row(
      children: [
        if (faves.isEmpty) SizedBox(width: 16),
        if (faves.isEmpty)
          Text(
            'No saved Locations so far',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (faves.isEmpty) Spacer(),
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
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                                  ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer,
                            onPressed: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ConnectionsPageAndroid(
                                    ConnectionsPage(
                                      from: Location(
                                        id: '',
                                        latitude: 0,
                                        longitude: 0,
                                        name: '',
                                        type: '',
                                      ),
                                      to: f.location,
                                      services: widget.page.service,
                                    ),
                                  ),
                                ),
                              ),
                            },
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        SizedBox(width: 14),
        IconButton(
          onPressed: () => _showEditFavoritesModal(context),
          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
          tooltip: 'Edit Saved Locations',
        ),
      ],
    );
  }

  Widget _stationResult(BuildContext context, Station station) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionsPageAndroid(
                ConnectionsPage(
                  from: Location(
                    id: '',
                    latitude: 0,
                    longitude: 0,
                    name: '',
                    type: '',
                  ),
                  to: station,
                  services: widget.page.service,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tonal avatar for the station icon
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

              // Station name + service icons
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
                          Icon(Icons.train, size: 20, color: colors.tertiary),
                        if (station.regionalExpress)
                          Icon(
                            Icons.directions_railway,
                            size: 20,
                            color: colors.tertiary,
                          ),
                        if (station.regional)
                          Icon(
                            Icons.directions_transit,
                            size: 20,
                            color: colors.tertiary,
                          ),
                        if (station.suburban)
                          Icon(
                            Icons.directions_subway,
                            size: 20,
                            color: colors.tertiary,
                          ),
                        if (station.bus)
                          Icon(
                            Icons.directions_bus,
                            size: 20,
                            color: colors.tertiary,
                          ),
                        if (station.ferry)
                          Icon(
                            Icons.directions_ferry,
                            size: 20,
                            color: colors.tertiary,
                          ),
                        if (station.subway)
                          Icon(Icons.subway, size: 20, color: colors.tertiary),
                        if (station.tram)
                          Icon(Icons.tram, size: 20, color: colors.tertiary),
                        if (station.taxi)
                          Icon(
                            Icons.local_taxi,
                            size: 20,
                            color: colors.tertiary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              buildFavouriteButton(context, station),

              // Trailing chevron
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionsPageAndroid(
                ConnectionsPage(
                  from: Location(
                    id: '',
                    latitude: 0,
                    longitude: 0,
                    name: '',
                    type: '',
                  ),
                  to: location,
                  services: widget.page.service,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tonal avatar for the “home” icon
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.tertiaryContainer,
                child: Icon(
                  Icons.house,
                  size: 24,
                  color: colors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // Location name
              Expanded(
                child: Text(
                  location.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),

              buildFavouriteButton(context, location),
              // Chevron affordance
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFavouriteButton(BuildContext context, Location location) {
    bool alreadyFave = false;
    FavoriteLocation? thatFave;
    for (int i = 0; i < faves.length; i++) {
      if (faves[i].location.id == location.id) {
        alreadyFave = true;
        thatFave = faves[i];
      }
    }

    if (alreadyFave) {
      return IconButton(
        icon: Icon(Icons.favorite),
        onPressed: () => {
          setState(() {
            faves.remove(thatFave);
            Localdatasaver.removeFavouriteLocation(thatFave!);
          }),
        },
      );
    }

    return IconButton(
      icon: Icon(Icons.favorite_border),
      onPressed: () => showDialog(
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Localdatasaver.addLocationToFavourites(location, c.text);
                  List<FavoriteLocation> updatedFaves =
                      await Localdatasaver.getFavouriteLocations();
                  setState(() {
                    faves = updatedFaves;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditFavoritesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 400),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final colors = Theme.of(context).colorScheme;
            final texts = Theme.of(context).textTheme;

            return Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: colors.primary, size: 28),
                          SizedBox(width: 16),
                          Text(
                            'Edit Saved Locations',
                            style: texts.headlineSmall!.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          if (faves.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${faves.length}',
                                style: texts.bodySmall!.copyWith(
                                  color: colors.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Content with drag and drop
                    Flexible(
                      child: faves.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 64,
                              color: colors.onSurfaceVariant.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No saved locations yet',
                              style: texts.titleMedium!.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add locations to favorites to manage them here. \n'
                                  'Do this by searching for a station or location and tapping the heart icon.',
                              style: texts.bodyMedium!.copyWith(
                                color: colors.onSurfaceVariant.withOpacity(0.7),
                              ),
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
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          List<FavoriteLocation> reorderedFaves = List.from(faves);
                          final item = reorderedFaves.removeAt(oldIndex);
                          reorderedFaves.insert(newIndex, item);

                          setState(() {
                            faves = reorderedFaves;
                          });
                          setModalState(() {
                            faves = reorderedFaves;
                          });

                          await _saveFavoriteOrder(reorderedFaves);
                        },
                        itemBuilder: (context, index) {
                          final fave = faves[index];
                          return Padding(
                            key: ValueKey('${fave.location.id}_$index'),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
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
                                title: Text(
                                  fave.name,
                                  style: texts.titleMedium!.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  fave.location.name,
                                  style: texts.bodySmall!.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: colors.primary, size: 20),
                                      onPressed: () => _showRenameFavoriteDialog(context, fave, setModalState),
                                      tooltip: 'Rename',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
                                      onPressed: () => _showDeleteFavoriteDialog(context, fave, setModalState),
                                      tooltip: 'Remove',
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors.outline.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: colors.onSurfaceVariant,
                                          size: 20,
                                        ),
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
      BuildContext context,
      FavoriteLocation fave,
      StateSetter setModalState,
      ) {
    final TextEditingController controller = TextEditingController(text: fave.name);
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Location',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: colors.onSurface,
              )),
          content: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: colors.onSurface,
            ),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Location Name',
              hintText: 'Enter new name',
              hintStyle: TextStyle(color: colors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  // Remove old favorite
                  await Localdatasaver.removeFavouriteLocation(fave);
                  // Add with new name
                  await Localdatasaver.addLocationToFavourites(
                    fave.location,
                    controller.text.trim(),
                  );

                  // Update local state
                  final updatedFaves = await Localdatasaver.getFavouriteLocations();
                  setState(() {
                    faves = updatedFaves;
                  });
                  setModalState(() {
                    faves = updatedFaves;
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFavoriteDialog(
      BuildContext context,
      FavoriteLocation fave,
      StateSetter setModalState,
      ) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Location',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: colors.onSurface,
              )),
          content: Text('Are you sure you want to remove "${fave.name}" from your saved locations?',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: colors.onSurfaceVariant,
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () async {
                await Localdatasaver.removeFavouriteLocation(fave);

                // Update local state
                final updatedFaves = await Localdatasaver.getFavouriteLocations();
                setState(() {
                  faves = updatedFaves;
                });
                setModalState(() {
                  faves = updatedFaves;
                });

                Navigator.of(context).pop();
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

