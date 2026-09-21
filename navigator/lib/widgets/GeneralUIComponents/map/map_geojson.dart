import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';

abstract final class MapGeoJson {
  static String lines(Iterable<NavigatorMapLine> lines) {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': lines
          .where((line) => line.points.length > 1)
          .map(
            (line) => {
              'type': 'Feature',
              'id': line.id,
              'properties': {
                'featureId': line.id,
                'color': color(line.color),
                'width': line.width,
                'borderColor': color(line.borderColor ?? Colors.transparent),
                'borderWidth': line.borderWidth,
                'dashed': line.dashed,
                ...line.properties,
              },
              'geometry': {
                'type': 'LineString',
                'coordinates': line.points
                    .map((point) => [point.longitude, point.latitude])
                    .toList(growable: false),
              },
            },
          )
          .toList(growable: false),
    });
  }

  static String points(Iterable<Map<String, Object?>> features) {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': features.toList(growable: false),
    });
  }

  static String mapPoints(Iterable<NavigatorMapPoint> points) {
    return MapGeoJson.points(
      points.map(
        (point) => pointFeature(
          id: point.id,
          latitude: point.point.latitude,
          longitude: point.point.longitude,
          properties: {
            'color': color(point.color),
            'strokeColor': color(point.strokeColor),
            'radius': point.radius,
            'strokeWidth': point.strokeWidth,
            'icon': point.icon,
            'iconSize': point.iconSize,
            'heading': point.heading,
            'accuracyRadius': point.accuracyRadius,
            'accuracyColor': color(point.accuracyColor),
            'label': point.label,
            'showLabel': point.showLabel,
            'labelColor': color(point.labelColor),
            'labelHaloColor': color(point.labelHaloColor),
            ...point.properties,
          },
        ),
      ),
    );
  }

  static Map<String, Object?> pointFeature({
    required String id,
    required double latitude,
    required double longitude,
    Map<String, Object?> properties = const {},
  }) {
    return {
      'type': 'Feature',
      'id': id,
      'properties': {'featureId': id, ...properties},
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    };
  }

  static String color(Color value) {
    final alpha = (value.a * 255).round();
    final red = (value.r * 255).round();
    final green = (value.g * 255).round();
    final blue = (value.b * 255).round();
    return '#${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}'
        '${alpha.toRadixString(16).padLeft(2, '0')}';
  }
}
