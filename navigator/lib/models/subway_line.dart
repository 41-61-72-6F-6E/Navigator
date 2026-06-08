import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/baseModel.dart';

class SubwayLine extends baseModel{
  final List<LatLng> points;
  final Color color;
  final String? lineName;
  final String? lineRef;
  final String? type;

  SubwayLine({
    required super.backend,
    required this.points,
    required this.color,
    this.lineName,
    this.lineRef,
    this.type
  });
}

// Helper function to parse color from string
Color parseColorFromString(String? colorString) {
  if (colorString == null || colorString.isEmpty) {
    return Colors.purple; // Default fallback color
  }

  // Remove # if present
  String cleanColor = colorString.replaceAll('#', '').toLowerCase();

  // First, handle named colors
  switch (cleanColor) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'brown':
      return Colors.brown;
    case 'pink':
      return Colors.pink;
    case 'cyan':
      return Colors.cyan;
    case 'lime':
      return Colors.lime;
  }

  try {
    // Handle 3-digit hex (e.g., "f00" -> "ff0000")
    if (cleanColor.length == 3) {
      cleanColor = cleanColor.split('').map((c) => c + c).join();
    }

    // Handle 6-digit hex
    if (cleanColor.length == 6) {
      return Color(int.parse('FF$cleanColor', radix: 16));
    }
  } catch (e) {
    print('Failed to parse color: $colorString, using default');
  }

  return Colors.purple; // Fallback on error
}