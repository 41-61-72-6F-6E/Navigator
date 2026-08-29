import 'package:navigator/models/baseModel.dart';
import 'package:navigator/models/leg.dart';

class Journey extends baseModel{
  final List<Leg> legs;
  final String refreshToken;


  Journey({
    required this.legs,
    required this.refreshToken,
    required super.backend,
  });

  factory Journey.fromJson(String backend, Map<String, dynamic> json) {
    Journey j = Journey(
      backend: backend,
      legs: (json['legs'] as List)
          .map((legJson) => Leg.fromJson(backend, legJson))
        .toList(),
        refreshToken: json['refreshToken'] ?? '');
    return j; // Extract it safely
    
  }

  void initializeLineColors()
  {
    for (var leg in legs)
    {
      leg.initializeLineColor();
    }
  }

  static Journey parseSingleJourneyResponse(String backend, Map<String, dynamic> json) {
    if (!json.containsKey('legs')) {
      throw FormatException('Missing legs in single journey response');
    }
    return Journey.fromJson(backend, json);
  }

  Map<String, dynamic> toJson() {
    return {
      'legs': legs.map((leg) => leg.toJson()).toList(),
      'refreshToken': refreshToken,
    };
  }

  static List<Journey> parseAndSort(String backend, List<dynamic> jsonJourneys) {
    List<Journey> journeys = jsonJourneys
        .map((json) {
      final journey = Journey.fromJson(backend, json);
      print('Parsed Journey with refreshToken: ${journey.refreshToken}');
      return journey;
    })
        .toList();

    journeys.sort((a, b) {
      DateTime departureA = a.legs.first.departureDateTime;
      DateTime departureB = b.legs.first.departureDateTime;
      return departureA.compareTo(departureB);
    });

    return journeys;
  }

  static List<Journey> parseAndSortByPlanned(String backend,List<dynamic> jsonJourneys) {
    List<Journey> journeys = jsonJourneys
        .map((json) {
      final journey = Journey.fromJson(backend, json);
      print('Parsed Journey with refreshToken: ${journey.refreshToken}');
      return journey;
    })
        .toList();

    // Sort by actual arrival time of the last leg
    journeys.sort((a, b) {
      DateTime arrivalA = a.legs.last.arrivalDateTime;
      DateTime arrivalB = b.legs.last.arrivalDateTime;
      return arrivalA.compareTo(arrivalB);
    });

    return journeys;
  }



  DateTime get departureTime => legs.first.departureDateTime;
  DateTime get arrivalTime => legs.last.arrivalDateTime;
  DateTime get plannedDepartureTime => legs.first.plannedDepartureDateTime;
  DateTime get plannedArrivalTime => legs.last.plannedArrivalDateTime;

  JourneyProgress progressAt(DateTime now) {
    if (legs.isEmpty) {
      throw StateError('Cannot determine progress for a journey without legs');
    }

    var currentLegIndex = 0;
    var isAfterCurrentLegArrival = false;

    for (var index = 0; index < legs.length; index++) {
      final leg = legs[index];

      if (now.isAfter(leg.departureDateTime)) {
        currentLegIndex = index;
        isAfterCurrentLegArrival = false;
      }
      if (now.isAfter(leg.arrivalDateTime)) {
        isAfterCurrentLegArrival = true;
      }
    }

    return JourneyProgress(
      currentLegIndex: currentLegIndex,
      isAfterCurrentLegArrival: isAfterCurrentLegArrival,
    );
  }
}

class JourneyProgress {
  final int currentLegIndex;
  final bool isAfterCurrentLegArrival;

  const JourneyProgress({
    required this.currentLegIndex,
    required this.isAfterCurrentLegArrival,
  });
}
