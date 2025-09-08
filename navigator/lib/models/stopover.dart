// New Stopover class to capture detailed intermediate stop information
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/station.dart';

class Stopover {
  final Station station;
  final String? arrival;
  final String? plannedArrival;
  final String? arrivalDelay;
  final String? arrivalPlatform;
  final String? plannedArrivalPlatform;
  final String? departure;
  final String? plannedDeparture;
  final String? departureDelay;
  final String? departurePlatform;
  final String? plannedDeparturePlatform;
  final List<Remark>? remarks;

  Stopover({
    required this.station,
    this.arrival,
    this.plannedArrival,
    this.arrivalDelay,
    this.arrivalPlatform,
    this.plannedArrivalPlatform,
    this.departure,
    this.plannedDeparture,
    this.departureDelay,
    this.departurePlatform,
    this.plannedDeparturePlatform,
    this.remarks,
  });

  factory Stopover.fromJson(Map<String, dynamic> json) {
    String? safeGetString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    Station station;
    try {
      station = Station.fromJson(json['stop']);
    } catch (e) {
      print('Error parsing station in stopover: $e');
      station = Station.empty();
    }

    List<Remark>? remarks = (json['remarks'] as List<dynamic>?)
        ?.map((item) => Remark.fromJson(item as Map<String, dynamic>))
        .toList();

    return Stopover(
      station: station,
      arrival: safeGetString(json['arrival']),
      plannedArrival: safeGetString(json['plannedArrival']),
      arrivalDelay: safeGetString(json['arrivalDelay']),
      arrivalPlatform: safeGetString(json['arrivalPlatform']),
      plannedArrivalPlatform: safeGetString(json['plannedArrivalPlatform']),
      departure: safeGetString(json['departure']),
      plannedDeparture: safeGetString(json['plannedDeparture']),
      departureDelay: safeGetString(json['departureDelay']),
      departurePlatform: safeGetString(json['departurePlatform']),
      plannedDeparturePlatform: safeGetString(json['plannedDeparturePlatform']),
      remarks: remarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop': station.toJson(),
      'arrival': arrival,
      'plannedArrival': plannedArrival,
      'arrivalDelay': arrivalDelay,
      'arrivalPlatform': arrivalPlatform,
      'plannedArrivalPlatform': plannedArrivalPlatform,
      'departure': departure,
      'plannedDeparture': plannedDeparture,
      'departureDelay': departureDelay,
      'departurePlatform': departurePlatform,
      'plannedDeparturePlatform': plannedDeparturePlatform,
      'remarks': remarks?.map((r) => r.toJson()).toList(),
    };
  }

  // Helper function to parse time strings to DateTime
  // Supports ISO 8601 format and Unix timestamps
  DateTime? _parseDateTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      // Try parsing as ISO 8601 format first (most common for APIs)
      if (timeString.contains('T') || timeString.contains('-')) {
        return DateTime.parse(timeString);
      }
      
      // Try parsing as Unix timestamp (milliseconds)
      final timestamp = int.tryParse(timeString);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      // Try parsing as Unix timestamp (seconds)
      final timestampSeconds = double.tryParse(timeString);
      if (timestampSeconds != null) {
        return DateTime.fromMillisecondsSinceEpoch((timestampSeconds * 1000).round());
      }
      
      return null;
    } catch (e) {
      print('Error parsing datetime from "$timeString": $e');
      return null;
    }
  }

  // DateTime conversion getters for all time fields
  DateTime? get arrivalDateTime => _parseDateTime(arrival);
  DateTime? get plannedArrivalDateTime => _parseDateTime(plannedArrival);
  DateTime? get departureDateTime => _parseDateTime(departure);
  DateTime? get plannedDepartureDateTime => _parseDateTime(plannedDeparture);

  // Effective DateTime getters (prioritize actual over planned)
  DateTime? get effectiveArrivalDateTime => arrivalDateTime ?? plannedArrivalDateTime;
  DateTime? get effectiveDepartureDateTime => departureDateTime ?? plannedDepartureDateTime;

  // Convert DateTime back to local timezone if needed
  DateTime? get arrivalDateTimeLocal => arrivalDateTime?.toLocal();
  DateTime? get plannedArrivalDateTimeLocal => plannedArrivalDateTime?.toLocal();
  DateTime? get departureDateTimeLocal => departureDateTime?.toLocal();
  DateTime? get plannedDepartureDateTimeLocal => plannedDepartureDateTime?.toLocal();
  DateTime? get effectiveArrivalDateTimeLocal => effectiveArrivalDateTime?.toLocal();
  DateTime? get effectiveDepartureDateTimeLocal => effectiveDepartureDateTime?.toLocal();

  // Convert DateTime to UTC if needed
  DateTime? get arrivalDateTimeUtc => arrivalDateTime?.toUtc();
  DateTime? get plannedArrivalDateTimeUtc => plannedArrivalDateTime?.toUtc();
  DateTime? get departureDateTimeUtc => departureDateTime?.toUtc();
  DateTime? get plannedDepartureDateTimeUtc => plannedDepartureDateTime?.toUtc();
  DateTime? get effectiveArrivalDateTimeUtc => effectiveArrivalDateTime?.toUtc();
  DateTime? get effectiveDepartureDateTimeUtc => effectiveDepartureDateTime?.toUtc();

  // Delay calculation helpers
  Duration? get arrivalDelayDuration {
    final planned = plannedArrivalDateTime;
    final actual = arrivalDateTime;
    if (planned == null || actual == null) return null;
    return actual.difference(planned);
  }

  Duration? get departureDelayDuration {
    final planned = plannedDepartureDateTime;
    final actual = departureDateTime;
    if (planned == null || actual == null) return null;
    return actual.difference(planned);
  }

  // Check if arrival/departure is delayed
  bool get isArrivalDelayed {
    final delay = arrivalDelayDuration;
    return delay != null && delay.inMinutes > 0;
  }

  bool get isDepartureDelayed {
    final delay = departureDelayDuration;
    return delay != null && delay.inMinutes > 0;
  }

  // Helper getters similar to those in Leg class
  String get effectiveArrival => arrival ?? plannedArrival ?? '';
  String get effectiveDeparture => departure ?? plannedDeparture ?? '';
  String get effectiveArrivalPlatform => arrivalPlatform ?? plannedArrivalPlatform ?? '';
  String get effectiveDeparturePlatform => departurePlatform ?? plannedDeparturePlatform ?? '';

  bool get isIntermediateStop =>
      (arrival != null || plannedArrival != null) &&
      (departure != null || plannedDeparture != null);
}