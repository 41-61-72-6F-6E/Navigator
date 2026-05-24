import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/trip.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/homePage/homePageUIState.dart';

/// Model class for the Home page
/// Handles all business logic and state management
class HomePageModel extends ChangeNotifier {
  final HomePageIni page;

  HomePageUIState _state = const HomePageUIState();
  HomePageUIState get state => _state;

  HomePageModel({required this.page});

  void _updateState(HomePageUIState newState) {
    _state = newState;
    notifyListeners();
  }

  // ─── Initialisation ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    await initiateLines();
    await fetchStations();
    await setInitialUserLocation();
    await initializeOngoingJourney();
    await getFaves();
  }

  Future<void> initializeOngoingJourney() async {
    await updateOngoingJourney();
    if (_state.ongoingJourney != null) {
      initializeOngoingJourneyLineColorListeners();
      await getOngoingJourneyTrips();
      updateOngoingJourneyPolylines();
    }
  }

  // ─── Lines ────────────────────────────────────────────────────────────────

  Future<void> initiateLines() async {
    await page.service.refreshPolylines();
    if (page.service.loadedSubwayLines.isNotEmpty) {
      final allLines = page.service.loadedSubwayLines
          .where((l) => l.points.isNotEmpty)
          .map((l) => Polyline(
                points: l.points,
                strokeWidth: 2.0,
                color: l.color,
                borderColor: l.color.withAlpha(60),
              ))
          .toList();

      _updateState(_state.copyWith(
        lines: allLines,
        subwayLines: _polylinesForType('subway'),
        lightRailLines: _polylinesForType('light_rail'),
        tramLines: _polylinesForType('tram'),
        ferryLines: _polylinesForType('ferry', strokeWidth: 1.0),
        funicularLines: _polylinesForType('funicular'),
      ));
    }
  }

  List<Polyline> _polylinesForType(String type, {double strokeWidth = 2.0}) {
    return page.service.loadedSubwayLines
        .where((l) => l.points.isNotEmpty && l.type == type)
        .map((l) => Polyline(
              points: l.points,
              strokeWidth: strokeWidth,
              color: l.color,
              borderColor: l.color.withAlpha(60),
            ))
        .toList();
  }

  // ─── Stations ─────────────────────────────────────────────────────────────

  Future<void> fetchStations() async {
    final location = await page.service.getCurrentLocation();
    if (location.latitude != 0 && location.longitude != 0) {
      try {
        final fetchedStations = await page.service.overpass.fetchStationsByType(
          lat: location.latitude,
          lon: location.longitude,
          radius: 50000,
        );
        _updateState(_state.copyWith(stations: fetchedStations));
      } catch (e) {
        print('Error fetching stations: $e');
      }
    }
  }

  // ─── User location ────────────────────────────────────────────────────────

  Future<void> setInitialUserLocation() async {
    final loc = await page.service.getCurrentLocation();
    if (loc.latitude != 0 && loc.longitude != 0) {
      final newCenter = LatLng(loc.latitude, loc.longitude);
      _updateState(_state.copyWith(
        currentUserLocation: newCenter,
        currentCenter: newCenter,
        currentZoom: 12.0,
      ));
      await fetchStations();
    }
  }

  void updateMapPosition(LatLng center, double zoom) {
    _updateState(_state.copyWith(currentCenter: center, currentZoom: zoom));
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<void> getSearchResults(String query) async {
    final results = await page.getLocations(query);
    _updateState(_state.copyWith(
      searchResults: results,
      lastSearchedText: query,
    ));
  }

  void clearSearch() {
    _updateState(_state.copyWith(
      searchResults: [],
      lastSearchedText: '',
    ));
  }

  // ─── Ongoing journey ──────────────────────────────────────────────────────

  Future<void> updateOngoingJourney() async {
    List<Savedjourney> journeys = await Localdatasaver.getSavedJourneys();
    for (Savedjourney sj in journeys) {
      if (DateTime.now().isAfter(sj.journey.plannedDepartureTime) &&
          DateTime.now().isBefore(sj.journey.arrivalTime)) {
        final refreshed = await page.service.refreshJourneyByToken(
          sj.journey.refreshToken,
        );
        final newJ = Savedjourney(
          journey: refreshed,
          id: Localdatasaver.calculateJourneyID(sj.journey),
        );
        _updateState(_state.copyWith(ongoingJourney: newJ));
        return;
      }
    }
  }

  Future<void> getOngoingJourneyTrips() async {
    if (_state.ongoingJourney == null) {
      print('DEBUG: No ongoing journey found');
      return;
    }

    print(
      'DEBUG: Processing ${_state.ongoingJourney!.journey.legs.length} legs for ongoing journey',
    );

    _updateState(_state.copyWith(
      legsOfOngoingJourneyThatHaveATrip: [],
      tripsForOngoingJourneyLegs: [],
      legIndexToTripMap: {},
    ));

    Map<int, Trip> legIndexToTrip = {};
    List<Leg> legs = _state.ongoingJourney!.journey.legs;

    for (int i = 0; i < legs.length; i++) {
      Leg leg = legs[i];
      print('DEBUG: Processing leg $i/${legs.length - 1}');
      print('DEBUG: - From: ${leg.origin.name}');
      print('DEBUG: - To: ${leg.destination.name}');
      print('DEBUG: - Product: ${leg.product}');
      print('DEBUG: - Line: ${leg.lineName}');
      print('DEBUG: - TripID: ${leg.tripID}');
      print('DEBUG: - IsWalking: ${leg.isWalking}');

      if (leg.isWalking != true &&
          leg.tripID != null &&
          leg.tripID!.isNotEmpty) {
        print(
          'DEBUG: Attempting to fetch trip for leg $i with tripID: ${leg.tripID}',
        );

        try {
          Trip? trip = await page.service.getTripFromLeg(
            leg,
            includeRemarks: true,
            includePolyline: false,
          );

          if (trip != null) {
            print('DEBUG: Successfully fetched trip for leg $i');
            print('DEBUG: - Trip ID: ${trip.id}');
            print('DEBUG: - Trip line: ${trip.line?.name}');
            print('DEBUG: - Stopovers count: ${trip.stopovers.length}');

            if (trip.stopovers.isNotEmpty) {
              print('DEBUG: - First stopover: ${trip.stopovers.first.station.name}');
              print('DEBUG: - Last stopover: ${trip.stopovers.last.station.name}');
              for (int j = 0; j < trip.stopovers.length; j++) {
                final stopover = trip.stopovers[j];
                print('DEBUG: - Stopover $j: ${stopover.station.name} at ${stopover.plannedArrival}');
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

    _updateState(_state.copyWith(
      legsOfOngoingJourneyThatHaveATrip: legIndexToTrip.keys.toList(),
      tripsForOngoingJourneyLegs: legIndexToTrip.values.toList(),
      legIndexToTripMap: legIndexToTrip,
    ));

    print(
      'DEBUG: State updated - legIndexToTripMap has ${_state.legIndexToTripMap.length} entries',
    );
    _state.legIndexToTripMap.forEach((legIndex, trip) {
      print('DEBUG: Leg $legIndex -> Trip ${trip.id} with ${trip.stopovers.length} stopovers');
    });
  }

  // ─── Ongoing journey line colours ─────────────────────────────────────────

  void initializeOngoingJourneyLineColorListeners() {
    if (_state.ongoingJourney != null) {
      for (Leg l in _state.ongoingJourney!.journey.legs) {
        l.lineColorNotifier.addListener(onLineColorChanged);
        l.initializeLineColor();
      }
    }
  }

  void onLineColorChanged() {
    updateOngoingJourneyPolylines();
  }

  void disposeOngoingJourneyLineColorListeners() {
    if (_state.ongoingJourney != null) {
      for (Leg l in _state.ongoingJourney!.journey.legs) {
        l.lineColorNotifier.removeListener(onLineColorChanged);
      }
    }
  }

  // ─── Ongoing journey polylines ────────────────────────────────────────────

  void updateOngoingJourneyPolylines() {
    _updateState(_state.copyWith(
      ongoingJourneyPolylines: extractOngoingJourneyPolylines(),
    ));
  }

  List<LatLng> extractPointsFromLegPolyline(dynamic polylineData) {
    List<LatLng> points = [];
    try {
      final Map<String, dynamic> geoJson = polylineData is Map<String, dynamic>
          ? polylineData
          : jsonDecode(polylineData);

      if (geoJson['type'] == 'FeatureCollection' && geoJson['features'] is List) {
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

  List<Polyline> extractOngoingJourneyPolylines() {
    if (_state.ongoingJourney == null) return [];

    final Map<String, Color> modeColors = {
      'train': const Color(0xFF9C27B0),
      'subway': const Color(0xFF0075BF),
      'tram': const Color(0xFFE4000F),
      'bus': const Color(0xFF9A258F),
      'ferry': const Color(0xFF0098D8),
      'walking': Colors.grey,
      'default': Colors.blue,
    };

    List<Polyline> polylines = [];
    // We need BuildContext for Theme — pass the cached color cache and current leg index from state.
    // Color resolution that requires Theme is handled in the view; here we resolve what we can.

    try {
      final colorCache = Map<String, Color>.from(_state.ongoingJourneyTransitLineColorCache);

      for (int i = 0; i < _state.ongoingJourney!.journey.legs.length; i++) {
        final leg = _state.ongoingJourney!.journey.legs[i];
        if (leg.polyline == null) continue;

        final List<LatLng> legPoints = extractPointsFromLegPolyline(leg.polyline);
        if (legPoints.isEmpty) continue;

        Color lineColor;
        if (leg.isWalking == true) {
          lineColor = modeColors['walking']!;
        } else {
          final String cacheKey = '${leg.lineName ?? ''}-${leg.productName ?? ''}';
          String productType = leg.productName?.toLowerCase() ?? 'default';

          lineColor = colorCache[cacheKey] ??
              leg.lineColorNotifier.value ??
              modeColors[productType] ??
              modeColors['default']!;

          if (!colorCache.containsKey(cacheKey)) {
            leg.lineColorNotifier.addListener(() {
              if (leg.lineColorNotifier.value != null) {
                final updatedCache = Map<String, Color>.from(
                    _state.ongoingJourneyTransitLineColorCache);
                updatedCache[cacheKey] = leg.lineColorNotifier.value!;
                _updateState(_state.copyWith(
                  ongoingJourneyTransitLineColorCache: updatedCache,
                ));
              }
            });
          }
        }

        double strokeWidth = leg.isWalking == true ? 1.0 : 3.0;
        if (_state.ongoingJourneyCurrentLegIndex != null &&
            _state.ongoingJourneyCurrentLegIndex == i) {
          strokeWidth = strokeWidth * 2;
        }

        // Border colour is theme-dependent; the view will re-call this via
        // updateOngoingJourneyPolylinesWithContext when it has a context.
        polylines.add(Polyline(
          borderColor: Colors.black, // default; overridden by view when context available
          borderStrokeWidth: 5,
          points: legPoints,
          color: lineColor,
          strokeWidth: strokeWidth,
          pattern: leg.isWalking == true
              ? StrokePattern.dotted()
              : StrokePattern.solid(),
        ));
      }
    } catch (e) {
      print('Error creating ongoing journey polylines: $e');
    }

    return polylines;
  }

  /// Called by the view (which has a BuildContext) so the border colour can
  /// use the correct theme value.
  List<Polyline> extractOngoingJourneyPolylinesWithContext(BuildContext context) {
    final raw = extractOngoingJourneyPolylines();
    final borderColor =
        Theme.of(context).colorScheme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
    return raw
        .map((p) => Polyline(
              borderColor: borderColor,
              borderStrokeWidth: p.borderStrokeWidth,
              points: p.points,
              color: p.color,
              strokeWidth: p.strokeWidth,
              pattern: p.pattern,
            ))
        .toList();
  }

  void updateOngoingJourneyPolylinesWithContext(BuildContext context) {
    _updateState(_state.copyWith(
      ongoingJourneyPolylines:
          extractOngoingJourneyPolylinesWithContext(context),
    ));
  }

  // ─── Current leg tracking ─────────────────────────────────────────────────

  void updateCurrentLegIndex(int? index) {
    _updateState(_state.copyWith(
      ongoingJourneyCurrentLegIndex: index,
      clearOngoingJourneyCurrentLegIndex: index == null,
    ));
  }

  // ─── Favourites ───────────────────────────────────────────────────────────

  Future<void> getFaves() async {
    List<FavoriteLocation> f = await Localdatasaver.getFavouriteLocations();
    _updateState(_state.copyWith(faves: f));
  }

  Future<void> saveFavoriteOrder(List<FavoriteLocation> reorderedFaves) async {
    try {
      for (FavoriteLocation fave in _state.faves) {
        await Localdatasaver.removeFavouriteLocation(fave);
      }
      for (FavoriteLocation fave in reorderedFaves) {
        await Localdatasaver.addLocationToFavourites(fave.location, fave.name);
      }
    } catch (e) {
      print('Error saving favorite order: $e');
    }
  }

  Future<void> renameFavorite(FavoriteLocation fave, String newName) async {
    await Localdatasaver.removeFavouriteLocation(fave);
    await Localdatasaver.addLocationToFavourites(fave.location, newName);
    final updatedFaves = await Localdatasaver.getFavouriteLocations();
    _updateState(_state.copyWith(faves: updatedFaves));
  }

  Future<void> removeFavorite(FavoriteLocation fave) async {
    await Localdatasaver.removeFavouriteLocation(fave);
    final updatedFaves = await Localdatasaver.getFavouriteLocations();
    _updateState(_state.copyWith(faves: updatedFaves));
  }

  Future<void> addFavorite(Location location, String name) async {
    await Localdatasaver.addLocationToFavourites(location, name);
    final updatedFaves = await Localdatasaver.getFavouriteLocations();
    _updateState(_state.copyWith(faves: updatedFaves));
  }

  // ─── UI toggles ───────────────────────────────────────────────────────────

  void toggleIntermediateStops() {
    _updateState(_state.copyWith(
      ongoingJourneyIntermediateStopsExpanded:
          !_state.ongoingJourneyIntermediateStopsExpanded,
    ));
  }

  void setMapOptions({
    bool? showLightRail,
    bool? showStationLabelsLightRail,
    bool? showSubway,
    bool? showStationLabelsSubway,
    bool? showTram,
    bool? showStationLabelsTram,
    bool? showFerry,
    bool? showStationLabelsFerry,
    bool? showFunicular,
    bool? showStationLabelsFunicular,
  }) {
    _updateState(_state.copyWith(
      showLightRail: showLightRail,
      showStationLabelsLightRail: showStationLabelsLightRail,
      showSubway: showSubway,
      showStationLabelsSubway: showStationLabelsSubway,
      showTram: showTram,
      showStationLabelsTram: showStationLabelsTram,
      showFerry: showFerry,
      showStationLabelsFerry: showStationLabelsFerry,
      showFunicular: showFunicular,
      showStationLabelsFunicular: showStationLabelsFunicular,
    ));
  }

  @override
  void dispose() {
    disposeOngoingJourneyLineColorListeners();
    if (_state.ongoingJourney != null) {
      for (final leg in _state.ongoingJourney!.journey.legs) {
        leg.lineColorNotifier.removeListener(() {});
      }
    }
    super.dispose();
  }
}