import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';
import 'package:navigator/widgets/journeyPage/journeyPageUIState.dart';

class JourneyPageAndroidModel extends ChangeNotifier {
  final JourneyPageIni page;
  final Journey journey;

  NavigatorMapCamera? _mapCamera;
  StreamSubscription<Position>? _geolocatorSubscription;

  JourneyPageAndroidUIState _state = const JourneyPageAndroidUIState();
  JourneyPageAndroidUIState get state => _state;

  JourneyPageAndroidModel({required this.page, required this.journey}) {
    updateIsSaved();
    _computeInitialMapPosition();
  }

  // ── State helpers ──────────────────────────────────────────────────────────

  void _updateState(JourneyPageAndroidUIState newState) {
    _state = newState;
    notifyListeners();
  }

  // ── Save / unsave ──────────────────────────────────────────────────────────

  Future<void> updateIsSaved() async {
    final s = await Localdatasaver.journeyIsSaved(journey);
    _updateState(_state.copyWith(isSaved: s));
  }

  Future<void> saveJourney() async {
    await Localdatasaver.saveJourney(journey);
    await updateIsSaved();
  }

  Future<void> removeSavedJourney() async {
    await Localdatasaver.removeSavedJourney(journey);
    await updateIsSaved();
  }

  // ── Map position helpers ───────────────────────────────────────────────────

  /// Calculates and stores the initial center/zoom that covers the full journey.
  void _computeInitialMapPosition() {
    if (journey.legs.isEmpty) return;

    final firstLeg = journey.legs.first;
    final lastLeg = journey.legs.last;

    final startLat = firstLeg.origin.latitude;
    final startLng = firstLeg.origin.longitude;
    final endLat = lastLeg.destination.latitude;
    final endLng = lastLeg.destination.longitude;

    final centerLat = (startLat + endLat) / 2;
    final centerLng = (startLng + endLng) / 2;

    final distance = calculateDistance(startLat, startLng, endLat, endLng);
    final zoom = calculateZoomLevel(distance);

    _updateState(
      _state.copyWith(
        currentCenter: LatLng(centerLat, centerLng),
        currentZoom: zoom,
      ),
    );
  }

  /// Keeps UIState in sync with the camera without triggering a rebuild.
  /// Called from the map's onPositionChanged – intentionally no notifyListeners.
  void updateCurrentPosition(LatLng center, double zoom) {
    _state = _state.copyWith(currentCenter: center, currentZoom: zoom);
  }

  void attachMapCamera(NavigatorMapCamera camera) {
    _mapCamera = camera;
    _initializeLocationTracking();
  }

  Future<void> moveMap(
    LatLng center,
    double zoom, {
    bool animate = false,
  }) async {
    updateCurrentPosition(center, zoom);
    if (animate) {
      await _mapCamera?.animateTo(
        center,
        zoom,
        duration: const Duration(milliseconds: 600),
      );
    } else {
      await _mapCamera?.moveTo(center, zoom);
    }
  }

  void updateTransitLineColorCache(String key, Color color) {
    final newCache = Map<String, Color>.from(_state.transitLineColorCache);
    newCache[key] = color;
    _updateState(_state.copyWith(transitLineColorCache: newCache));
  }

  // ── Focus helpers (used by view) ───────────────────────────────────────────

  /// Returns the (center, zoom) that best frames a given [leg].
  (LatLng center, double zoom) getLegFocusPoint(Leg leg) {
    final startLat = leg.origin.latitude;
    final startLng = leg.origin.longitude;
    final endLat = leg.destination.latitude;
    final endLng = leg.destination.longitude;

    final centerLat = (startLat + endLat) / 2;
    final centerLng = (startLng + endLng) / 2;

    final distanceKm = calculateDistance(startLat, startLng, endLat, endLng);
    return (LatLng(centerLat, centerLng), calculateLegZoom(distanceKm));
  }

  // ── Math helpers ───────────────────────────────────────────────────────────

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = degreesToRadians(lat2 - lat1);
    final double dLng = degreesToRadians(lng2 - lng1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(degreesToRadians(lat1)) *
            math.cos(degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double degreesToRadians(double degrees) => degrees * math.pi / 180;

  double calculateZoomLevel(double distanceKm) {
    if (distanceKm < 1) return 17.0;
    if (distanceKm < 5) return 14.0;
    if (distanceKm < 20) return 12.0;
    if (distanceKm < 50) return 10.0;
    if (distanceKm < 200) return 8.0;
    return 6.0;
  }

  double calculateLegZoom(double distanceKm) {
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

  // ── Location tracking ──────────────────────────────────────────────────────

  void _initializeLocationTracking() {
    if (_geolocatorSubscription != null) return;
    _geolocatorSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen(
          (Position position) {
            _updateState(
              _state.copyWith(
                currentUserLocation: LatLng(
                  position.latitude,
                  position.longitude,
                ),
                locationAccuracy: position.accuracy,
                locationHeading: position.heading,
              ),
            );
          },
          onError: (Object error) {
            debugPrint('Unable to track current location: $error');
          },
        );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _geolocatorSubscription?.cancel();
    super.dispose();
  }
}
