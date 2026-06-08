import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class MapPositionNotifier extends ChangeNotifier {
  double currentZoom;
  LatLng currentCenter;
  LatLng? currentUserLocation;
  AlignOnUpdate alignPositionOnUpdate;

  MapPositionNotifier({
    this.currentZoom = 12.0,
    LatLng? currentCenter,
    this.currentUserLocation,
    this.alignPositionOnUpdate = AlignOnUpdate.never,
  }) : currentCenter = currentCenter ?? const LatLng(52.52, 13.405);

  void update({
    double? currentZoom,
    LatLng? currentCenter,
    LatLng? currentUserLocation,
    AlignOnUpdate? alignPositionOnUpdate,
    bool clearUserLocation = false,
  }) {
    if (currentZoom != null) this.currentZoom = currentZoom;
    if (currentCenter != null) this.currentCenter = currentCenter;
    if (clearUserLocation) {
      this.currentUserLocation = null;
    } else if (currentUserLocation != null) {
      this.currentUserLocation = currentUserLocation;
    }
    if (alignPositionOnUpdate != null) {
      this.alignPositionOnUpdate = alignPositionOnUpdate;
    }
    notifyListeners();
  }
}