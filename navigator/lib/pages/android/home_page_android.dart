import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:navigator/models/favouriteLocation.dart';
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
    setState(() {});
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
                            duration: Duration(milliseconds: 300),
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
        // Always visible button row
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
        
        // Expandable content with ClipRect for smooth animation
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.center,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            heightFactor: ongoingJourneyIntermediateStopsExpanded ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                  onPressed: () {},
                  label: Text(
                    'Show Map',
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
        lowerBox = Text('Take some form of transportation');
        break;
      case 1:
        lowerBox = Text('1 = Get off at');
        break;
      case 2:
        lowerBox = Text('Walk somewhere');
        break;
      case 3:
        lowerBox = Text('Arrival');
    }

    return AnimatedSize(
      duration: Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        width: double.infinity,
        duration: Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
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
                lowerBox,
              ],
            ),
          ),
        ),
      ),
    );
  }

  String prettyPrintTime(DateTime time) {
    return '${time.hour}:${time.minute}';
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

  Widget _buildFaves(BuildContext context) {
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
        Spacer(),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
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
}
