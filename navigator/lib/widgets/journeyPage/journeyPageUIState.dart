import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class JourneyPageAndroidUIState {
  final bool isSaved;
  final LatLng? currentUserLocation;
  final LatLng currentCenter;
  final double currentZoom;
  final double locationAccuracy;
  final double locationHeading;
  final Map<String, Color> transitLineColorCache;

  const JourneyPageAndroidUIState({
    this.isSaved = false,
    this.currentUserLocation,
    this.currentCenter = const LatLng(52.513416, 13.412364),
    this.currentZoom = 10,
    this.locationAccuracy = 0,
    this.locationHeading = 0,
    this.transitLineColorCache = const {},
  });

  JourneyPageAndroidUIState copyWith({
    bool? isSaved,
    LatLng? currentUserLocation,
    LatLng? currentCenter,
    double? currentZoom,
    double? locationAccuracy,
    double? locationHeading,
    Map<String, Color>? transitLineColorCache,
  }) {
    return JourneyPageAndroidUIState(
      isSaved: isSaved ?? this.isSaved,
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      currentCenter: currentCenter ?? this.currentCenter,
      currentZoom: currentZoom ?? this.currentZoom,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      locationHeading: locationHeading ?? this.locationHeading,
      transitLineColorCache:
          transitLineColorCache ?? this.transitLineColorCache,
    );
  }
}
