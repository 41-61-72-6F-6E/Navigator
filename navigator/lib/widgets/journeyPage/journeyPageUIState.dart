import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class JourneyPageAndroidUIState {
  final bool isSaved;
  final LatLng? currentUserLocation;
  final LatLng currentCenter;
  final double currentZoom;
  final AlignOnUpdate alignPositionOnUpdate;
  final Map<String, Color> transitLineColorCache;

  const JourneyPageAndroidUIState({
    this.isSaved = false,
    this.currentUserLocation,
    this.currentCenter = const LatLng(52.513416, 13.412364),
    this.currentZoom = 10,
    this.alignPositionOnUpdate = AlignOnUpdate.never,
    this.transitLineColorCache = const {},
  });

  JourneyPageAndroidUIState copyWith({
    bool? isSaved,
    LatLng? currentUserLocation,
    LatLng? currentCenter,
    double? currentZoom,
    AlignOnUpdate? alignPositionOnUpdate,
    Map<String, Color>? transitLineColorCache,
  }) {
    return JourneyPageAndroidUIState(
      isSaved: isSaved ?? this.isSaved,
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      currentCenter: currentCenter ?? this.currentCenter,
      currentZoom: currentZoom ?? this.currentZoom,
      alignPositionOnUpdate:
          alignPositionOnUpdate ?? this.alignPositionOnUpdate,
      transitLineColorCache:
          transitLineColorCache ?? this.transitLineColorCache,
    );
  }
}