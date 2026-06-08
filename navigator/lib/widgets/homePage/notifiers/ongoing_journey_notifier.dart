import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/trip.dart';

class OngoingJourneyNotifier extends ChangeNotifier {
  Savedjourney? ongoingJourney;
  Map<int, Trip> legIndexToTripMap;
  List<int> legsOfOngoingJourneyThatHaveATrip;
  List<Trip> tripsForOngoingJourneyLegs;
  List<Polyline> polylines;
  Map<String, Color> transitLineColorCache;
  bool intermediateStopsExpanded;
  int? currentLegIndex;
  bool lowerBoxExpanded;

  OngoingJourneyNotifier({
    this.ongoingJourney,
    this.legIndexToTripMap = const {},
    this.legsOfOngoingJourneyThatHaveATrip = const [],
    this.tripsForOngoingJourneyLegs = const [],
    this.polylines = const [],
    this.transitLineColorCache = const {},
    this.intermediateStopsExpanded = false,
    this.currentLegIndex,
    this.lowerBoxExpanded = false,
  });

  void updateJourney(Savedjourney? journey) {
    ongoingJourney = journey;
    notifyListeners();
  }

  void updateTrips({
    required Map<int, Trip> legIndexToTripMap,
    required List<int> legsOfOngoingJourneyThatHaveATrip,
    required List<Trip> tripsForOngoingJourneyLegs,
  }) {
    this.legIndexToTripMap = legIndexToTripMap;
    this.legsOfOngoingJourneyThatHaveATrip = legsOfOngoingJourneyThatHaveATrip;
    this.tripsForOngoingJourneyLegs = tripsForOngoingJourneyLegs;
    notifyListeners();
  }

  void updatePolylines(List<Polyline> polylines) {
    this.polylines = polylines;
    notifyListeners();
  }

  void updateTransitLineColorCache(Map<String, Color> cache) {
    transitLineColorCache = cache;
    notifyListeners();
  }

  void toggleIntermediateStops() {
    intermediateStopsExpanded = !intermediateStopsExpanded;
    notifyListeners();
  }

  void setCurrentLegIndex(int? index) {
    currentLegIndex = index;
    notifyListeners();
  }
}