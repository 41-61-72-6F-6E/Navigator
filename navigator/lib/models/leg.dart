import 'package:flutter/material.dart';
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/services/overpassApi.dart';

class Leg {
  final String? tripID;
  final String? direction;
  final Station origin;
  final String? departure;
  final String plannedDeparture;
  final String? departureDelay;
  final String? departurePlatform;
  final String? plannedDeparturePlatform;
  final Station destination;
  final String? arrival;
  final String plannedArrival;
  final String? arrivalDelay;
  final String? arrivalPlatform;
  final String? plannedArrivalPlatform;
  final dynamic polyline;
  final String? product;


  // Additional fields
  final bool? isWalking;
  final int? distance;
  final String? lineName;
  final String? productName;
  final List<Remark>? remarks;
  final ValueNotifier<Color?> lineColorNotifier = ValueNotifier<Color?>(null);

  Leg({
    this.tripID,
    this.direction,
    required this.origin,
    this.departure,
    required this.plannedDeparture,
    this.departureDelay,
    this.departurePlatform,
    this.plannedDeparturePlatform,
    required this.destination,
    this.arrival,
    required this.plannedArrival,
    this.arrivalDelay,
    this.arrivalPlatform,
    this.plannedArrivalPlatform,
    this.isWalking,
    this.distance,
    this.lineName,
    this.productName,
    this.polyline,
    this.remarks,
    this.product
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    String? safeGetString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    String? safeGetNestedString(Map<String, dynamic>? parent, String key) {
      if (parent == null) return null;
      final value = parent[key];
      if (value == null) return null;
      return value.toString();
    }

    Station safeGetStation(dynamic stationJson) {
      if (stationJson == null) return Station.empty();
      try {
        return Station.fromJson(stationJson);
      } catch (e) {
        print('Error parsing station: $e');
        return Station.empty();
      }
    }

    List<Remark>? remarks = (json['remarks'] as List<dynamic>?)
    ?.map((item) => Remark.fromJson(item as Map<String, dynamic>))
    .toList();

    

    return Leg(
      tripID: safeGetString(json['tripId']),
      direction: safeGetString(json['direction']),
      origin: safeGetStation(json['origin']),
      departure: safeGetString(json['departure']),
      plannedDeparture: safeGetString(json['plannedDeparture']) ?? '',
      departureDelay: safeGetString(json['departureDelay']),
      departurePlatform: safeGetString(json['departurePlatform']),
      plannedDeparturePlatform: safeGetString(json['plannedDeparturePlatform']),
      destination: safeGetStation(json['destination']),
      arrival: safeGetString(json['arrival']),
      plannedArrival: safeGetString(json['plannedArrival']) ?? '',
      arrivalDelay: safeGetString(json['arrivalDelay']),
      arrivalPlatform: safeGetString(json['arrivalPlatform']),
      plannedArrivalPlatform: safeGetString(json['plannedArrivalPlatform']),
      isWalking: json['walking'],
      distance: json['distance'],
      lineName: safeGetNestedString(json['line'], 'name'),
      productName: safeGetNestedString(json['line'], 'productName'),
      polyline: json['polyline'], // Optional, can be null
      remarks: remarks,
      product: safeGetNestedString(json['line'], 'product')
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripID,
      'direction': direction,
      'origin': origin.toJson(),
      'departure': departure,
      'plannedDeparture': plannedDeparture,
      'departureDelay': departureDelay,
      'departurePlatform': departurePlatform,
      'plannedDeparturePlatform': plannedDeparturePlatform,
      'destination': destination.toJson(),
      'arrival': arrival,
      'plannedArrival': plannedArrival,
      'arrivalDelay': arrivalDelay,
      'arrivalPlatform': arrivalPlatform,
      'plannedArrivalPlatform': plannedArrivalPlatform,
      'walking': isWalking,
      'distance': distance,
      'line': lineName != null || productName != null ? {
        'name': lineName,
        'productName': productName,
        'product': product
      } : null,
      if (polyline != null) 'polyline': polyline,
    };
  }

  void initializeLineColor() async
  {
    if(lineName!= null && lineName!.isNotEmpty)
    {
      final Overpassapi overpassApi = Overpassapi();
      lineColorNotifier.value = await overpassApi.getTransitLineColor(lat: origin.latitude, lon: origin.longitude,lineName:  lineName!, lineRef: tripID);
      final color = lineColorNotifier.value;
      print('Line color for $lineName: $color');
    }
  }

  // Helper getters for effective times
  String get effectiveDeparture => departure ?? plannedDeparture;
  String get effectiveArrival => arrival ?? plannedArrival;
  String get effectiveDeparturePlatform =>
      departurePlatform ?? plannedDeparturePlatform ?? '';

  String get effectiveArrivalPlatform =>
      arrivalPlatform ?? plannedArrivalPlatform ?? '';


      String get effectiveDepartureFormatted {
    final isoString = effectiveDeparture;
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'unknown';
    }
  }

  String get effectiveArrivalFormatted {
    final isoString = effectiveArrival;
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  String toString() {
    if (isWalking == true) {
      return 'Walking from ${origin.name} to ${destination.name} (${distance}m, ${_formatDuration()})';
    }
    String departureTime = '';
    String arrivalTime = '';
    try {
      departureTime = effectiveDeparture.split('T')[1].substring(0, 5);
      arrivalTime = effectiveArrival.split('T')[1].substring(0, 5);
    } catch (e) {
      departureTime = 'unknown';
      arrivalTime = 'unknown';
    }
    return '$lineName from ${origin.name} to ${destination.name} '
        '($departureTime - $arrivalTime)';
  }

  String _formatDuration() {
    try {
      if (effectiveDeparture.isEmpty || effectiveArrival.isEmpty) return 'unknown';
      final dep = DateTime.parse(effectiveDeparture);
      final arr = DateTime.parse(effectiveArrival);
      final duration = arr.difference(dep);
      return '${duration.inMinutes}min';
    } catch (e) {
      return 'unknown';
    }
  }

  DateTime get departureDateTime {
    final parsed = DateTime.parse(effectiveDeparture);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  DateTime get arrivalDateTime {
    final parsed = DateTime.parse(effectiveArrival);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  DateTime get plannedDepartureDateTime {
    final dateStr = plannedDeparture.isNotEmpty ? plannedDeparture : effectiveDeparture;
    final parsed = DateTime.parse(dateStr);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  DateTime get plannedArrivalDateTime {
    final dateStr = plannedArrival.isNotEmpty ? plannedArrival : effectiveArrival;
    final parsed = DateTime.parse(dateStr);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  bool get hasDelays {
    final depDelay = departureDelay != null ? int.tryParse(departureDelay!) ?? 0 : 0;
    final arrDelay = arrivalDelay != null ? int.tryParse(arrivalDelay!) ?? 0 : 0;
    return depDelay > 0 || arrDelay > 0;
  }

  int? get departureDelayMinutes {
    if (departureDelay == null) return null;

    final seconds = int.tryParse(departureDelay!);
    if (seconds == null) return null;

    return (seconds / 60).ceil();
  }

  int? get arrivalDelayMinutes {
    if (arrivalDelay == null) return null;

    final seconds = int.tryParse(arrivalDelay!);
    if (seconds == null) return null;

    return (seconds / 60).ceil();
  }

  bool platformChange(Leg nextLeg) {
    final currentArrival = arrivalPlatformEffective;
    final nextDeparture = nextLeg.departurePlatformEffective;
    return currentArrival.isNotEmpty &&
        nextDeparture.isNotEmpty &&
        currentArrival != nextDeparture;
  }

  // Returns actual departure platform, or planned, or empty string
  String get departurePlatformEffective =>
      departurePlatform?.isNotEmpty == true
          ? departurePlatform!
          : (plannedDeparturePlatform ?? '');

// Returns planned departure platform, or actual, or empty string
  String get plannedDeparturePlatformEffective =>
      plannedDeparturePlatform?.isNotEmpty == true
          ? plannedDeparturePlatform!
          : (departurePlatform ?? '');

// Returns actual arrival platform, or planned, or empty string
  String get arrivalPlatformEffective =>
      arrivalPlatform?.isNotEmpty == true
          ? arrivalPlatform!
          : (plannedArrivalPlatform ?? '');

// Returns planned arrival platform, or actual, or empty string
  String get plannedArrivalPlatformEffective =>
      plannedArrivalPlatform?.isNotEmpty == true
          ? plannedArrivalPlatform!
          : (arrivalPlatform ?? '');

}