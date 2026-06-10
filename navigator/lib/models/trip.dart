import 'package:navigator/models/baseModel.dart';
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/models/line.dart';

class Trip extends baseModel{
  final String id;
  final String? name;
  final String? direction;
  final Line? line;
  final String? origin;
  final String? destination;
  final DateTime? departure;
  final DateTime? plannedDeparture;
  final int? departureDelay;
  final String? departurePlatform;
  final String? plannedDeparturePlatform;
  final DateTime? arrival;
  final DateTime? plannedArrival;
  final int? arrivalDelay;
  final String? arrivalPlatform;
  final String? plannedArrivalPlatform;
  final List<Stopover> stopovers;
  final List<Remark> remarks;
  final dynamic polyline;

  Trip({
    required super.backend,
    required this.id,
    this.name,
    this.direction,
    this.line,
    this.origin,
    this.destination,
    this.departure,
    this.plannedDeparture,
    this.departureDelay,
    this.departurePlatform,
    this.plannedDeparturePlatform,
    this.arrival,
    this.plannedArrival,
    this.arrivalDelay,
    this.arrivalPlatform,
    this.plannedArrivalPlatform,
    this.stopovers = const [],
    this.remarks = const [],
    this.polyline,
  });

  factory Trip.fromJson(String backend, Map<String, dynamic> json) {
    return Trip(
      backend: backend,
      id: json['id'] ?? '',
      name: json['name'],
      direction: json['direction'],
      line: json['line'] != null ? Line.fromJson(backend, json['line']) : null,
      // Fix: Extract name from origin/destination objects
      origin: json['origin'] is Map ? json['origin']['name'] : json['origin'],
      destination: json['destination'] is Map ? json['destination']['name'] : json['destination'],
      departure: json['departure'] != null ? DateTime.parse(json['departure']) : null,
      plannedDeparture: json['plannedDeparture'] != null ? DateTime.parse(json['plannedDeparture']) : null,
      departureDelay: json['departureDelay'],
      departurePlatform: json['departurePlatform'],
      plannedDeparturePlatform: json['plannedDeparturePlatform'],
      arrival: json['arrival'] != null ? DateTime.parse(json['arrival']) : null,
      plannedArrival: json['plannedArrival'] != null ? DateTime.parse(json['plannedArrival']) : null,
      arrivalDelay: json['arrivalDelay'],
      arrivalPlatform: json['arrivalPlatform'],
      plannedArrivalPlatform: json['plannedArrivalPlatform'],
      stopovers: json['stopovers'] != null 
        ? (json['stopovers'] as List).map((s) => Stopover.fromJson(backend,s)).toList()
        : [],
      remarks: json['remarks'] != null 
        ? (json['remarks'] as List).map((r) => Remark.fromJson(backend, r)).toList()
        : [],
      polyline: json['polyline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'direction': direction,
      'line': line?.toJson(),
      'origin': origin,
      'destination': destination,
      'departure': departure?.toIso8601String(),
      'plannedDeparture': plannedDeparture?.toIso8601String(),
      'departureDelay': departureDelay,
      'departurePlatform': departurePlatform,
      'plannedDeparturePlatform': plannedDeparturePlatform,
      'arrival': arrival?.toIso8601String(),
      'plannedArrival': plannedArrival?.toIso8601String(),
      'arrivalDelay': arrivalDelay,
      'arrivalPlatform': arrivalPlatform,
      'plannedArrivalPlatform': plannedArrivalPlatform,
      'stopovers': stopovers.map((s) => s.toJson()).toList(),
      'remarks': remarks.map((r) => r.toJson()).toList(),
      'polyline': polyline,
    };
  }

  void debugPrintStopovers() {
    print('test');
    for(Stopover s in stopovers) {
      print(s.station.name);
    }
  }
}