import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapPositionNotifier extends ChangeNotifier {
  double currentZoom;
  LatLng currentCenter;
  LatLng? currentUserLocation;
  double locationAccuracy;
  double locationHeading;

  MapPositionNotifier({
    this.currentZoom = 12.0,
    LatLng? currentCenter,
    this.currentUserLocation,
    this.locationAccuracy = 0,
    this.locationHeading = 0,
  }) : currentCenter = currentCenter ?? const LatLng(52.52, 13.405);

  void update({
    double? currentZoom,
    LatLng? currentCenter,
    LatLng? currentUserLocation,
    double? locationAccuracy,
    double? locationHeading,
    bool clearUserLocation = false,
  }) {
    if (currentZoom != null) this.currentZoom = currentZoom;
    if (currentCenter != null) this.currentCenter = currentCenter;
    if (clearUserLocation) {
      this.currentUserLocation = null;
    } else if (currentUserLocation != null) {
      this.currentUserLocation = currentUserLocation;
    }
    if (locationAccuracy != null) this.locationAccuracy = locationAccuracy;
    if (locationHeading != null) this.locationHeading = locationHeading;
    notifyListeners();
  }
}
