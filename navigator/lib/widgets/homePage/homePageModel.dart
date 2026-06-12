import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/models/subway_line.dart';
import 'package:navigator/models/trip.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPage.dart';
import 'package:navigator/widgets/homePage/notifiers/faves_notifier.dart';
import 'package:navigator/widgets/homePage/notifiers/map_layers_notifier.dart';
import 'package:navigator/widgets/homePage/notifiers/map_position_notifier.dart';
import 'package:navigator/widgets/homePage/notifiers/ongoing_journey_notifier.dart';
import 'package:navigator/widgets/homePage/notifiers/station_sheet_notifier.dart';
import 'dart:math' as math;

typedef TransitLinesLoader =
    Future<List<SubwayLine>> Function({
      required double lat,
      required double lon,
      required int radius,
    });

typedef TransitStationsLoader =
    Future<List<Station>> Function({
      required double lat,
      required double lon,
      required int radius,
    });

class _LoadResult<T> {
  final T? value;
  final Object? error;

  const _LoadResult.success(this.value) : error = null;
  const _LoadResult.failure(this.error) : value = null;
}

class HomePageModel {
  static const int overlayRadiusMeters = 20000;
  static const double overlayReloadDistanceKm = 8;

  final HomePageIni page;
  final ServicesMiddle services;

  // ─── Notifiers ───────────────────────────────────────────────────────────

  final MapPositionNotifier position = MapPositionNotifier();
  final MapLayersNotifier layers = MapLayersNotifier();
  final OngoingJourneyNotifier journey = OngoingJourneyNotifier();
  final FavesNotifier faves = FavesNotifier();
  final StationSheetNotifier stationSheetNotifier = StationSheetNotifier();

  // ─── Controllers ─────────────────────────────────────────────────────────

  final MapController mapController = MapController();
  final StreamController<double?> alignPositionStreamController =
      StreamController<double?>.broadcast();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  Timer? _overlayReloadDebounce;
  Timer? _ongoingJourneySyncTimer;
  bool _ongoingJourneySyncInProgress = false;
  bool _ongoingJourneySyncPaused = false;
  bool _disposed = false;
  int _overlayLoadGeneration = 0;
  LatLng? _lastOverlayCenter;
  DateTime? _lastOverlayLoadedAt;

  final Duration ongoingJourneySyncInterval;
  late final Future<List<Savedjourney>> Function() _loadSavedJourneys;
  late final Future<Journey> Function(String) _refreshJourneyByToken;
  late final Future<Location> Function() _getCurrentLocation;
  late final TransitLinesLoader _loadTransitLines;
  late final TransitStationsLoader _loadTransitStations;
  late final DateTime Function() _now;

  HomePageModel({
    required this.page,
    required this.services,
    this.ongoingJourneySyncInterval = const Duration(minutes: 1),
    Future<List<Savedjourney>> Function()? loadSavedJourneys,
    Future<Journey> Function(String)? refreshJourneyByToken,
    Future<Location> Function()? getCurrentLocation,
    TransitLinesLoader? loadTransitLines,
    TransitStationsLoader? loadTransitStations,
    DateTime Function()? now,
  }) : assert(ongoingJourneySyncInterval > Duration.zero) {
    _loadSavedJourneys = loadSavedJourneys ?? Localdatasaver.getSavedJourneys;
    _refreshJourneyByToken =
        refreshJourneyByToken ?? services.refreshJourneyByToken;
    _getCurrentLocation = getCurrentLocation ?? services.getCurrentLocation;
    _loadTransitLines =
        loadTransitLines ?? services.overpass.fetchSubwayLinesWithColors;
    _loadTransitStations =
        loadTransitStations ?? services.overpass.fetchStationsByType;
    _now = now ?? DateTime.now;
    searchController.addListener(() {
      _onSearchChanged(searchController.text.trim());
    });
  }

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await Future.wait([
      initializeMap(),
      initializeOngoingJourney(),
      getFaves(),
    ]);
  }

  /// Resolves location once, then uses that same center for both overlay
  /// requests. If location is unavailable, the visible map center is still a
  /// useful fallback instead of querying around the invalid (0, 0) coordinate.
  Future<void> initializeMap({TickerProvider? vsync}) async {
    final location = await _getCurrentLocation();
    final hasLocation = location.latitude != 0 || location.longitude != 0;
    final center = hasLocation
        ? LatLng(location.latitude, location.longitude)
        : position.currentCenter;

    if (_disposed) return;
    if (hasLocation) {
      position.update(currentUserLocation: center);
      if (vsync != null) animatedMapMove(center, 12.5, vsync);
    }

    await loadMapOverlaysAt(center);
  }

  Future<void> initializeOngoingJourney() async {
    await syncOngoingJourney();
    _startOngoingJourneySync();
  }

  void _startOngoingJourneySync() {
    _ongoingJourneySyncTimer?.cancel();
    if (_disposed || _ongoingJourneySyncPaused) return;

    _ongoingJourneySyncTimer = Timer.periodic(
      ongoingJourneySyncInterval,
      (_) => unawaited(syncOngoingJourney()),
    );
  }

  void pauseOngoingJourneySync() {
    _ongoingJourneySyncPaused = true;
    _ongoingJourneySyncTimer?.cancel();
    _ongoingJourneySyncTimer = null;
  }

  void resumeOngoingJourneySync() {
    if (_disposed) return;
    _ongoingJourneySyncPaused = false;
    unawaited(syncOngoingJourney());
    _startOngoingJourneySync();
  }

  Future<void> syncOngoingJourney() async {
    if (_disposed || _ongoingJourneySyncInProgress) return;

    _ongoingJourneySyncInProgress = true;
    try {
      final savedJourneys = await _loadSavedJourneys();
      if (_disposed) return;

      final activeJourney = await _findOngoingJourney(savedJourneys);
      if (_disposed) return;

      if (activeJourney == null) {
        _clearOngoingJourney();
        return;
      }

      await _showOngoingJourney(activeJourney);
    } catch (error) {
      // A temporary storage or network failure should not make an otherwise
      // active journey disappear. The next timer tick will retry the sync.
      if (!_disposed) {
        journey.notifyCurrentTimeChanged();
        debugPrint('Error syncing ongoing journey: $error');
      }
    } finally {
      _ongoingJourneySyncInProgress = false;
    }
  }

  Future<Savedjourney?> _findOngoingJourney(
    List<Savedjourney> savedJourneys,
  ) async {
    final current = journey.ongoingJourney;
    Savedjourney? savedCurrent;

    if (current != null) {
      for (final savedJourney in savedJourneys) {
        if (savedJourney.id == current.id) {
          savedCurrent = savedJourney;
          break;
        }
      }
    }

    final candidates = <Savedjourney>[
      if (savedCurrent != null) savedCurrent,
      ...savedJourneys.where(
        (savedJourney) =>
            savedJourney.id != savedCurrent?.id &&
            _isOngoing(savedJourney.journey, _now()),
      ),
    ];

    for (final candidate in candidates) {
      final isCurrent = current != null && candidate.id == current.id;
      final journeyToRefresh = isCurrent ? current.journey : candidate.journey;

      try {
        final refreshed = await _refreshJourneyByToken(
          journeyToRefresh.refreshToken,
        );
        if (_disposed) return null;

        if (_isOngoing(refreshed, _now())) {
          return Savedjourney(journey: refreshed, id: candidate.id);
        }
      } catch (error) {
        final fallback = isCurrent ? current.journey : candidate.journey;
        if (_isOngoing(fallback, _now())) {
          debugPrint('Error refreshing ongoing journey: $error');
          return Savedjourney(journey: fallback, id: candidate.id);
        }
      }
    }

    return null;
  }

  bool _isOngoing(Journey candidate, DateTime now) {
    if (candidate.legs.isEmpty) return false;
    return !now.isBefore(candidate.departureTime) &&
        now.isBefore(candidate.arrivalTime);
  }

  Future<void> _showOngoingJourney(Savedjourney activeJourney) async {
    _disposeOngoingJourneyLineColorListener();
    journey.updateJourney(activeJourney);
    _initializeOngoingJourneyLineColorListener();
    await _getOngoingJourneyTrips();

    if (!_disposed && journey.ongoingJourney == activeJourney) {
      _updateOngoingJourneyPolylines();
    }
  }

  void _clearOngoingJourney() {
    if (journey.ongoingJourney == null) return;
    _disposeOngoingJourneyLineColorListener();
    journey.clearJourney();
  }

  Future<void> _getOngoingJourneyTrips() async {
    final ongoingJourney = journey.ongoingJourney;
    if (ongoingJourney == null || _disposed) {
      print('DEBUG: No ongoing journey found');
      return;
    }

    print(
      'DEBUG: Processing ${journey.ongoingJourney!.journey.legs.length} legs for ongoing journey',
    );

    journey.updateTrips(
      legIndexToTripMap: {},
      legsOfOngoingJourneyThatHaveATrip: [],
      tripsForOngoingJourneyLegs: [],
    );

    Map<int, Trip> legIndexToTrip = {};
    List<Leg> legs = ongoingJourney.journey.legs;

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
          Trip? trip = await services.getTripFromLeg(
            leg,
            includeRemarks: true,
            includePolyline: false,
          );

          if (_disposed || journey.ongoingJourney != ongoingJourney) return;

          if (trip != null) {
            print('DEBUG: Successfully fetched trip for leg $i');
            print('DEBUG: - Trip ID: ${trip.id}');
            print('DEBUG: - Trip line: ${trip.line?.name}');
            print('DEBUG: - Stopovers count: ${trip.stopovers.length}');

            if (trip.stopovers.isNotEmpty) {
              print(
                'DEBUG: - First stopover: ${trip.stopovers.first.station.name}',
              );
              print(
                'DEBUG: - Last stopover: ${trip.stopovers.last.station.name}',
              );
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

    if (!_disposed && journey.ongoingJourney == ongoingJourney) {
      journey.updateTrips(
        legIndexToTripMap: legIndexToTrip,
        legsOfOngoingJourneyThatHaveATrip: legIndexToTrip.keys.toList(),
        tripsForOngoingJourneyLegs: legIndexToTrip.values.toList(),
      );
    }

    print(
      'DEBUG: journey.legIndexToTripMap has ${journey.legIndexToTripMap.length} entries',
    );
    journey.legIndexToTripMap.forEach((legIndex, trip) {
      print(
        'DEBUG: Leg $legIndex -> Trip ${trip.id} with ${trip.stopovers.length} stopovers',
      );
    });
  }

  void _initializeOngoingJourneyLineColorListener() {
    if (journey.ongoingJourney != null) {
      for (Leg l in journey.ongoingJourney!.journey.legs) {
        final cachedColor =
            journey.transitLineColorCache[_lineColorCacheKey(l)];
        if (cachedColor != null) {
          l.lineColorNotifier.value = cachedColor;
        }
        l.lineColorNotifier.addListener(_updateLineColor);
        if (cachedColor == null) {
          l.initializeLineColor();
        }
      }
    }
  }

  void _updateLineColor() {
    if (_disposed) return;

    final updatedColors = Map<String, Color>.from(
      journey.transitLineColorCache,
    );
    for (final leg in journey.ongoingJourney?.journey.legs ?? <Leg>[]) {
      final color = leg.lineColorNotifier.value;
      if (color != null) {
        updatedColors[_lineColorCacheKey(leg)] = color;
      }
    }
    journey.updateTransitLineColorCache(updatedColors);
    _updateOngoingJourneyPolylines();
  }

  String _lineColorCacheKey(Leg leg) =>
      '${leg.lineName ?? ''}-${leg.productName ?? ''}';

  void _disposeOngoingJourneyLineColorListener() {
    if (journey.ongoingJourney != null) {
      for (Leg l in journey.ongoingJourney!.journey.legs) {
        l.lineColorNotifier.removeListener(_updateLineColor);
      }
    }
  }

  Future<void> getFaves() async {
    List<FavoriteLocation> f = await Localdatasaver.getFavouriteLocations();
    faves.updateFaves(f);
  }

  Future<void> saveFavoriteOrder(List<FavoriteLocation> reorderedFaves) async {
    try {
      for (FavoriteLocation fave in faves.faves) {
        await Localdatasaver.removeFavouriteLocation(fave);
      }
      for (FavoriteLocation fave in reorderedFaves) {
        await Localdatasaver.addLocationToFavourites(fave.location, fave.name);
      }
    } catch (e) {
      print('Error saving favorite order: $e');
    }
  }

  void _updateOngoingJourneyPolylines() {
    journey.updatePolylines(_extractOngoingJourneyPolylines());
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

  List<Polyline> _extractOngoingJourneyPolylines() {
    if (journey.ongoingJourney == null) return [];

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

    final bool isDark = _cachedIsDark;

    try {
      final colorCache = Map<String, Color>.from(journey.transitLineColorCache);

      for (int i = 0; i < journey.ongoingJourney!.journey.legs.length; i++) {
        final leg = journey.ongoingJourney!.journey.legs[i];
        if (leg.polyline == null) continue;

        final List<LatLng> legPoints = _extractPointsFromLegPolyline(
          leg.polyline,
        );
        if (legPoints.isEmpty) continue;

        Color lineColor;

        if (leg.isWalking == true) {
          lineColor = modeColors['walking']!;
        } else {
          final String cacheKey = _lineColorCacheKey(leg);
          String productType = leg.productName?.toLowerCase() ?? 'default';

          lineColor =
              colorCache[cacheKey] ??
              leg.lineColorNotifier.value ??
              modeColors[productType] ??
              modeColors['default']!;
        }

        double strokeWidth = leg.isWalking == true ? 1.0 : 3.0;
        if (journey.currentLegIndex != null && journey.currentLegIndex == i) {
          strokeWidth = strokeWidth * 2;
        }

        polylines.add(
          Polyline(
            borderColor: isDark ? Colors.white : Colors.black,
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

  bool _cachedIsDark = false;
  void updateBrightness(bool isDark) {
    if (_cachedIsDark != isDark) {
      _cachedIsDark = isDark;
    }
  }

  // ─── Map ─────────────────────────────────────────────────────────────────

  void animatedMapMove(
    LatLng destLocation,
    double destZoom,
    TickerProvider vsync,
  ) {
    final latTween = Tween<double>(
      begin: position.currentCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: position.currentCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: position.currentZoom, end: destZoom);

    var controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );

    Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    controller.addListener(() {
      mapController.move(
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

  Future<void> setInitialUserLocation(TickerProvider vsync) async {
    await initializeMap(vsync: vsync);
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && position.alignPositionOnUpdate != AlignOnUpdate.never) {
      position.update(alignPositionOnUpdate: AlignOnUpdate.never);
    }

    final newZoom = camera.zoom;
    final oldZoom = position.currentZoom;

    // Only notify marker layer listeners when zoom crosses a render threshold.
    // For pure pan (no zoom change crossing a threshold), update silently.
    if (_zoomCrossedThreshold(oldZoom, newZoom)) {
      position.update(currentZoom: newZoom, currentCenter: camera.center);
    } else {
      position.currentZoom = newZoom;
      position.currentCenter = camera.center;
    }

    if (hasGesture) {
      _scheduleOverlayReload(camera.center);
    }
  }

  void _scheduleOverlayReload(LatLng center) {
    final lastCenter = _lastOverlayCenter;
    if (lastCenter != null &&
        _calculateDistance(
              lastCenter.latitude,
              lastCenter.longitude,
              center.latitude,
              center.longitude,
            ) <
            overlayReloadDistanceKm) {
      return;
    }

    _overlayReloadDebounce?.cancel();
    _overlayReloadDebounce = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(loadMapOverlaysAt(center)),
    );
  }

  bool _zoomCrossedThreshold(double oldZoom, double newZoom) {
    const thresholds = [12.0, 14.0, 14.5, 15.5, 16.5, 17.0];
    for (final t in thresholds) {
      if ((oldZoom < t) != (newZoom < t)) return true;
    }
    return false;
  }

  void recenterMap() {
    position.update(alignPositionOnUpdate: AlignOnUpdate.always);
    alignPositionStreamController.add(18);
  }

  void focusMapOnLeg(Leg leg) {
    print("Focusing map on leg: ${leg.origin.name} to ${leg.destination.name}");

    final startLat = leg.origin.latitude;
    final startLng = leg.origin.longitude;
    final endLat = leg.destination.latitude;
    final endLng = leg.destination.longitude;

    final double north = math.max(startLat, endLat);
    final double south = math.min(startLat, endLat);
    final double east = math.max(startLng, endLng);
    final double west = math.min(startLng, endLng);

    final centerLat = (north + south) / 2;
    final centerLng = (east + west) / 2;
    final legCenter = LatLng(centerLat, centerLng);

    final distanceKm = _calculateDistance(startLat, startLng, endLat, endLng);
    final legZoom = _calculateLegZoom(distanceKm);

    print("Leg center: $legCenter, zoom: $legZoom");

    Future.microtask(() {
      position.update(
        alignPositionOnUpdate: AlignOnUpdate.never,
        currentCenter: legCenter,
        currentZoom: legZoom,
      );
      mapController.move(legCenter, legZoom);
    });
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  double _calculateLegZoom(double distanceKm) {
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

  // ─── Stations & Lines ────────────────────────────────────────────────────

  Future<void> initiateLines() async {
    final center = position.currentCenter;
    final lines = await _loadTransitLines(
      lat: center.latitude,
      lon: center.longitude,
      radius: overlayRadiusMeters,
    );
    if (!_disposed) _updateTransitLines(lines);
  }

  Future<void> fetchStations() async {
    final center = position.currentCenter;
    final stations = await _loadTransitStations(
      lat: center.latitude,
      lon: center.longitude,
      radius: overlayRadiusMeters,
    );
    if (!_disposed) layers.updateStations(stations);
  }

  Future<void> loadMapOverlaysAt(LatLng center) async {
    if (_disposed) return;
    final generation = ++_overlayLoadGeneration;
    layers.updateOverlayStatus(isLoading: true, clearError: true);

    final linesFuture = _capture(
      _loadTransitLines(
        lat: center.latitude,
        lon: center.longitude,
        radius: overlayRadiusMeters,
      ),
    );
    final stationsFuture = _capture(
      _loadTransitStations(
        lat: center.latitude,
        lon: center.longitude,
        radius: overlayRadiusMeters,
      ),
    );
    final linesResult = await linesFuture;
    final stationsResult = await stationsFuture;

    if (_disposed || generation != _overlayLoadGeneration) return;

    var loadedAnything = false;
    if (linesResult.value != null) {
      _updateTransitLines(linesResult.value!);
      loadedAnything = true;
    }
    if (stationsResult.value != null) {
      layers.updateStations(stationsResult.value!);
      loadedAnything = true;
    }
    if (loadedAnything) {
      _lastOverlayCenter = center;
      _lastOverlayLoadedAt = _now();
    }

    final errors = [
      linesResult.error,
      stationsResult.error,
    ].whereType<Object>().map((error) => error.toString()).toSet().join('\n');
    layers.updateOverlayStatus(
      isLoading: false,
      error: errors.isEmpty ? null : errors,
      clearError: errors.isEmpty,
      lastUpdated: loadedAnything ? _lastOverlayLoadedAt : null,
    );
  }

  Future<_LoadResult<T>> _capture<T>(Future<T> future) async {
    try {
      return _LoadResult.success(await future);
    } catch (error) {
      debugPrint('Error loading map overlay: $error');
      return _LoadResult.failure(error);
    }
  }

  void _updateTransitLines(List<SubwayLine> transitLines) {
    List<Polyline> polylinesFor(String? type, {double strokeWidth = 2}) {
      return transitLines
          .where(
            (line) =>
                line.points.isNotEmpty && (type == null || line.type == type),
          )
          .map(
            (line) => Polyline(
              points: line.points,
              strokeWidth: strokeWidth,
              color: line.color,
              borderColor: line.color.withAlpha(60),
            ),
          )
          .toList(growable: false);
    }

    layers.updateLines(
      lines: polylinesFor(null),
      subwayLines: polylinesFor('subway'),
      lightRailLines: polylinesFor('light_rail'),
      tramLines: polylinesFor('tram'),
      ferryLines: polylinesFor('ferry', strokeWidth: 1),
      funicularLines: polylinesFor('funicular'),
    );
  }

  void resumeMapDataLoading() {
    if (_disposed) return;
    final lastLoaded = _lastOverlayLoadedAt;
    final needsReload =
        layers.overlayError != null ||
        layers.lines.isEmpty ||
        layers.stations.isEmpty ||
        lastLoaded == null ||
        _now().difference(lastLoaded) > const Duration(minutes: 15);
    if (needsReload) {
      unawaited(loadMapOverlaysAt(position.currentCenter));
    }
  }

  Future<void> getDeparturesForStation(Station station) async {
    stationSheetNotifier.setLoading(true);
    try {
      final departures = await page.service.getDeparturesForStation(station);
      stationSheetNotifier.updateDepartures(departures);
    } catch (e) {
      print('Error fetching departures for station ${station.name}: $e');
    }
    stationSheetNotifier.setLoading(false);
  }

  Future<void> getarrivalsForStation(Station station) async {
    stationSheetNotifier.setLoading(true);
    try {
      final arrivals = await page.service.getArrivalsForStation(station);
      stationSheetNotifier.updateArrivals(arrivals);
    } catch (e) {
      print('Error fetching arrivals for station ${station.name}: $e');
    }
    stationSheetNotifier.setLoading(false);
  }

  void navigateLocation(
    BuildContext context,
    Location location,
    bool useAsOrigin,
  ) {
    final emptyLocation = Location(
      backend: "dbRest",
      id: '',
      latitude: 0,
      longitude: 0,
      name: '',
      type: '',
    );
    final origin = useAsOrigin ? location : emptyLocation;
    final destination = useAsOrigin ? emptyLocation : location;

    Navigator.of(context, rootNavigator: false).push(
      MaterialPageRoute(
        builder: (_) => ConnectionsPage(
          ConnectionsPageIni(
            from: origin,
            to: destination,
            services: page.service,
          ),
        ),
      ),
    );
  }

  Future<void> selectStation(Station station) async {
    stationSheetNotifier.setLoading(true);
    final convertedStation = await services.convertStationToDifferentBackend(
      station,
      "dbRest",
    );
    if (convertedStation == null) {
      print("Error converting station ${station.name} to the current backend format");
      stationSheetNotifier.setLoading(false);
      return;
    }
    stationSheetNotifier.selectStation(convertedStation);
    await getDeparturesForStation(convertedStation);
  }

  void deselectStation()
  {
    print("deselecting");
    stationSheetNotifier.selectedStation = null;
    stationSheetNotifier.clearDeparturesAndArrivals();
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query != faves.lastSearchedText) {
        getSearchResults(query);
        faves.setLastSearchedText(query);
      }
    });
  }

  Future<void> getSearchResults(String query) async {
    final results = await page.getLocations(query);
    faves.updateSearchResults(results);
  }

  void clearSearch() {
    faves.clearSearch();
    searchController.clear();
  }

  // ─── Favourites ──────────────────────────────────────────────────────────

  Future<void> reloadFaves() async {
    List<FavoriteLocation> updatedFaves =
        await Localdatasaver.getFavouriteLocations();
    faves.updateFaves(updatedFaves);
  }

  Future<void> addFavourite(Location location, String name) async {
    await Localdatasaver.addLocationToFavourites(location, name);
    await reloadFaves();
  }

  Future<void> removeFavourite(FavoriteLocation fave) async {
    await Localdatasaver.removeFavouriteLocation(fave);
    final updated = List<FavoriteLocation>.from(faves.faves)..remove(fave);
    faves.updateFaves(updated);
  }

  // ─── Map Options ─────────────────────────────────────────────────────────

  void updateMapOptions({
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
    layers.updateVisibility(
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
    );
  }

  // ─── Ongoing Journey UI ──────────────────────────────────────────────────

  void toggleIntermediateStops() {
    journey.toggleIntermediateStops();
  }

  void setOngoingJourneyCurrentLegIndex(int? index) {
    journey.setCurrentLegIndex(index);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  double getMinZoomForStation(Station station) {
    if (station.national || station.nationalExpress) return 9.5;
    if (station.regional || station.regionalExpress) return 10.5;
    if (station.suburban || station.subway) return 12.5;
    if (station.tram || station.ferry || station.bus || station.taxi)
      return 14.5;
    return 16.5;
  }

  bool getShowLabels(String transportType) =>
      layers.getShowLabels(transportType);

  bool shouldShowStation(Station station, String transportType) {
    switch (transportType) {
      case 'rail':
        return station.national ||
            station.nationalExpress ||
            station.regional ||
            station.regionalExpress;
      case 'lightRail':
        return station.suburban;
      case 'subway':
        return station.subway;
      case 'tram':
        return station.tram;
      case 'ferry':
        return station.ferry;
      case 'funicular':
        return false;
      default:
        return false;
    }
  }

  String getLabelCollisionKey(Station station, double zoom) {
    double gridSize = 100;
    if (zoom > 16.5)
      gridSize = 150;
    else if (zoom > 15.5)
      gridSize = 120;
    final gridX = (station.latitude * 1000 / gridSize).round();
    final gridY = (station.longitude * 1000 / gridSize).round();
    return "$gridX:$gridY";
  }

  bool haveSameRil100Station(List<String> ril100Ids1, List<String> ril100Ids2) {
    if (ril100Ids1.isEmpty || ril100Ids2.isEmpty) return false;
    for (String id1 in ril100Ids1) {
      for (String id2 in ril100Ids2) {
        if (id1 == id2) return true;
      }
    }
    return false;
  }

  String prettyPrintTime(DateTime time) {
    String hour = '${time.hour}'.padLeft(2, '0');
    String minute = '${time.minute}'.padLeft(2, '0');
    return '$hour:$minute';
  }

  String generateStopoverTimeText(Stopover s) {
    String timeText = '';
    if (s.arrivalDateTime != null && s.departureDateTime != null) {
      if (s.arrivalDateTime!.hour == s.departureDateTime!.hour &&
          s.arrivalDateTime!.minute == s.departureDateTime!.minute) {
        timeText = prettyPrintTime(s.arrivalDateTimeLocal!);
      } else {
        timeText =
            '${prettyPrintTime(s.arrivalDateTimeLocal!)} - ${prettyPrintTime(s.departureDateTimeLocal!)}';
      }
    } else {
      if (s.arrivalDateTime == null) {
        timeText = prettyPrintTime(s.departureDateTimeLocal!);
      } else {
        timeText = prettyPrintTime(s.arrivalDateTimeLocal!);
      }
    }
    return timeText;
  }

  IconData getTransportIcon(Station station) {
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

  void dispose() {
    _disposed = true;
    _overlayLoadGeneration++;
    pauseOngoingJourneySync();
    _debounce?.cancel();
    _overlayReloadDebounce?.cancel();
    searchController.dispose();
    alignPositionStreamController.close();
    _disposeOngoingJourneyLineColorListener();
    if (journey.ongoingJourney != null) {
      for (final leg in journey.ongoingJourney!.journey.legs) {
        leg.lineColorNotifier.removeListener(() {});
      }
    }
    position.dispose();
    layers.dispose();
    journey.dispose();
    faves.dispose();
  }
}
