import 'package:navigator/models/line.dart';
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/station.dart';

class DepartureArrival {
  final Station station;
  final DateTime when;
  final DateTime plannedWhen;
  final int? delay;
  final String? platform;
  final String? plannedPlatform;
  final String? direction;
  final String? provenance;
  final Line? line;
  final List<Remark> remarks;
  final Station? origin;
  final Station? destination;
  final bool isDeparture;

  DepartureArrival({
    required this.station,
    required this.when,
    required this.plannedWhen,
    this.delay,
    this.platform,
    this.plannedPlatform,
    this.direction,
    this.provenance,
    this.line,
    this.remarks = const [],
    this.origin,
    this.destination,
    required this.isDeparture,
  });

  factory DepartureArrival.fromJson(Map<String, dynamic> json, {required bool isDeparture}) {
    return DepartureArrival(
      station: Station.fromJson(json['station']),
      when: DateTime.parse(json['when']),
      plannedWhen: DateTime.parse(json['plannedWhen']),
      delay: json['delay'],
      platform: json['platform'],
      plannedPlatform: json['plannedPlatform'],
      direction: json['direction'],
      provenance: json['provenance'],
      line: json['line'] != null ? Line.fromJson(json['line']) : null,
      remarks: (json['remarks'] as List<dynamic>?)
              ?.map((remarkJson) => Remark.fromJson(remarkJson))
              .toList() ??
          [],
      origin: json['origin'] != null ? Station.fromJson(json['origin']) : null,
      destination:
          json['destination'] != null ? Station.fromJson(json['destination']) : null,
      isDeparture: isDeparture,
    );
  }

  }