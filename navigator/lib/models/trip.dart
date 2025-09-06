import 'package:navigator/models/remark.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/stopover.dart';

class Trip {
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

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      name: json['name'],
      direction: json['direction'],
      line: json['line'] != null ? Line.fromJson(json['line']) : null,
      origin: json['origin'],
      destination: json['destination'],
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
        ? (json['stopovers'] as List).map((s) => Stopover.fromJson(s)).toList()
        : [],
      remarks: json['remarks'] != null 
        ? (json['remarks'] as List).map((r) => Remark.fromJson(r)).toList()
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
}

class Line {
  final String type;
  final String? id;
  final String? fahrtNr;
  final String name;
  final bool public;
  final String? adminCode;
  final String? productName;
  final String mode;
  final String product;
  final Operator? operator;

  Line({
    required this.type,
    this.id,
    this.fahrtNr,
    required this.name,
    required this.public,
    this.adminCode,
    this.productName,
    required this.mode,
    required this.product,
    this.operator,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      type: json['type'] ?? '',
      id: json['id'],
      fahrtNr: json['fahrtNr'],
      name: json['name'] ?? '',
      public: json['public'] ?? true,
      adminCode: json['adminCode'],
      productName: json['productName'],
      mode: json['mode'] ?? '',
      product: json['product'] ?? '',
      operator: json['operator'] != null ? Operator.fromJson(json['operator']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'fahrtNr': fahrtNr,
      'name': name,
      'public': public,
      'adminCode': adminCode,
      'productName': productName,
      'mode': mode,
      'product': product,
      'operator': operator?.toJson(),
    };
  }
}

class Operator {
  final String type;
  final String id;
  final String name;

  Operator({
    required this.type,
    required this.id,
    required this.name,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
    };
  }
}