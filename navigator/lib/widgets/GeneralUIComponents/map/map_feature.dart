import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Renderer-neutral line data consumed by the MapLibre map widgets.
class NavigatorMapLine {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;
  final Color? borderColor;
  final double borderWidth;
  final bool dashed;
  final Map<String, Object?> properties;

  const NavigatorMapLine({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
    this.borderColor,
    this.borderWidth = 0,
    this.dashed = false,
    this.properties = const {},
  });
}

/// Renderer-neutral point data used for stations and the current location.
class NavigatorMapPoint {
  final String id;
  final LatLng point;
  final String label;
  final Color color;
  final Color strokeColor;
  final double radius;
  final double strokeWidth;
  final String icon;
  final double iconSize;
  final double heading;
  final double accuracyRadius;
  final Color accuracyColor;
  final bool showLabel;
  final Color labelColor;
  final Color labelHaloColor;
  final Map<String, Object?> properties;

  const NavigatorMapPoint({
    required this.id,
    required this.point,
    this.label = '',
    required this.color,
    required this.strokeColor,
    this.radius = 6,
    this.strokeWidth = 1.5,
    this.icon = '',
    this.iconSize = 0.16,
    this.heading = 0,
    this.accuracyRadius = 0,
    this.accuracyColor = Colors.transparent,
    this.showLabel = false,
    this.labelColor = Colors.black,
    this.labelHaloColor = Colors.white,
    this.properties = const {},
  });
}

/// Small abstraction that keeps page models independent from MapLibre APIs.
abstract interface class NavigatorMapCamera {
  Future<void> moveTo(LatLng center, double zoom);

  Future<void> animateTo(
    LatLng center,
    double zoom, {
    Duration duration = const Duration(milliseconds: 500),
  });
}
