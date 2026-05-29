import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/models/journeySettings.dart';

/// Holds all mutable data for the connections screen.
/// No Flutter widgets here – only plain Dart types plus
/// TimeOfDay / DateTime which are value objects.
class ConnectionsPageModel {
  // ── Search state ──────────────────────────────────────────────────────────
  List<Location> searchResultsFrom = [];
  List<Location> searchResultsTo = [];
  String lastSearchedText = '';

  // ── Journey results ───────────────────────────────────────────────────────
  List<Journey>? currentJourneys;

  // ── Date / time ───────────────────────────────────────────────────────────
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();

  // ── Mode ──────────────────────────────────────────────────────────────────
  /// true = departure, false = arrival
  bool departure = true;

  // ── Favourites ────────────────────────────────────────────────────────────
  List<FavoriteLocation> faves = [];

  // ── Journey preferences ───────────────────────────────────────────────────
  JourneySettings journeySettings = JourneySettings(
    nationalExpress: true,
    national: true,
    regionalExpress: true,
    regional: true,
    suburban: true,
    subway: true,
    tram: true,
    bus: true,
    ferry: true,
    deutschlandTicketConnectionsOnly: false,
    accessibility: false,
    walkingSpeed: 'normal',
    transferTime: null,
  );

  // ── Service / page model (injected) ──────────────────────────────────────
  late ConnectionsPageIni page;

  // ── Async helpers ─────────────────────────────────────────────────────────

  Future<void> loadFavourites() async {
    faves = await Localdatasaver.getFavouriteLocations();
  }

  Future<Location> fetchCurrentLocation() =>
      page.services.getCurrentLocation();

  Future<List<Location>> fetchSearchResults(String query) =>
      page.services.getLocations(query);

  Future<List<Journey>> fetchJourneys(
    Location from,
    Location to,
    DateAndTime when,
    bool departure,
  ) =>
      page.services.getJourneys(
        from,
        to,
        when,
        departure,
        journeySettings: journeySettings,
      );

  Future<List<Journey>> fetchEarlierJourneys() =>
      page.services.getJourneysEarlierThanLastSearch();

  Future<List<Journey>> fetchLaterJourneys() =>
      page.services.getJourneysLaterThanLastSearch();

  Future<Journey> refreshJourney(Journey j) =>
      page.services.refreshJourney(j);

  // ── Journey helpers (pure logic) ─────────────────────────────────────────

  int? getShortestInterchange(Journey journey) {
    if (journey.legs.isEmpty) return null;

    List<int> interchangeTimes = [];
    List<int> transitLegIndices = [];

    for (int index = 0; index < journey.legs.length; index++) {
      final leg = journey.legs[index];
      if (leg.isWalking == true) continue;
      bool isSameStationInterchange =
          leg.origin.id == leg.destination.id &&
          leg.origin.name == leg.destination.name;
      if (!isSameStationInterchange) transitLegIndices.add(index);
    }

    for (int i = 1; i < transitLegIndices.length; i++) {
      final currentLegIndex = transitLegIndices[i];
      final currentLeg = journey.legs[currentLegIndex];
      final previousLegIndex = transitLegIndices[i - 1];
      final previousLeg = journey.legs[previousLegIndex];

      bool shouldCalculateInterchange = false;

      if (previousLeg.destination.id == currentLeg.origin.id &&
          previousLeg.destination.name == currentLeg.origin.name &&
          previousLeg.lineName != currentLeg.lineName) {
        shouldCalculateInterchange = true;
      } else if (previousLeg.destination.ril100Ids.isNotEmpty &&
          currentLeg.origin.ril100Ids.isNotEmpty &&
          haveSameRil100ID(
            previousLeg.destination.ril100Ids,
            currentLeg.origin.ril100Ids,
          ) &&
          previousLeg.lineName != currentLeg.lineName) {
        shouldCalculateInterchange = true;
      } else if (currentLegIndex - previousLegIndex > 1) {
        for (int interchangeIndex = previousLegIndex + 1;
            interchangeIndex < currentLegIndex;
            interchangeIndex++) {
          final interchangeLeg = journey.legs[interchangeIndex];
          if ((interchangeLeg.origin.id == interchangeLeg.destination.id &&
                  interchangeLeg.origin.name ==
                      interchangeLeg.destination.name) ||
              (interchangeLeg.origin.id == previousLeg.destination.id &&
                  interchangeLeg.destination.id == currentLeg.origin.id)) {
            shouldCalculateInterchange = true;
            break;
          }
        }
      }

      if (shouldCalculateInterchange) {
        try {
          final arrivalTime = previousLeg.arrivalDateTime;
          final departureTime = currentLeg.departureDateTime;
          final interchangeMinutes =
              departureTime.difference(arrivalTime).inMinutes;
          if (interchangeMinutes > 0) interchangeTimes.add(interchangeMinutes);
        } catch (e) {
          print('Error calculating interchange time: $e');
          continue;
        }
      }
    }

    if (interchangeTimes.isEmpty) return null;
    return interchangeTimes.reduce((a, b) => a < b ? a : b);
  }

  int calculateTotalInterchanges(Journey journey) {
    if (journey.legs.isEmpty) return 0;

    int interchangeCount = 0;
    List<int> transitLegIndices = [];

    for (int index = 0; index < journey.legs.length; index++) {
      final leg = journey.legs[index];
      bool isSameStationInterchange =
          leg.origin.id == leg.destination.id &&
          leg.origin.name == leg.destination.name;
      bool isTransitLeg =
          !isSameStationInterchange && leg.isWalking != true;
      if (isTransitLeg) transitLegIndices.add(index);
    }

    for (int i = 1; i < transitLegIndices.length; i++) {
      final legIndex = transitLegIndices[i];
      final leg = journey.legs[legIndex];
      final previousLegIndex = transitLegIndices[i - 1];
      final previousLeg = journey.legs[previousLegIndex];

      bool shouldCountInterchange = false;

      if (legIndex - previousLegIndex > 1) {
        shouldCountInterchange = true;
      } else if (previousLeg.destination.id == leg.origin.id &&
          previousLeg.destination.name == leg.origin.name &&
          previousLeg.lineName != leg.lineName) {
        shouldCountInterchange = true;
      } else if (previousLeg.destination.ril100Ids.isNotEmpty &&
          leg.origin.ril100Ids.isNotEmpty &&
          haveSameRil100ID(
            previousLeg.destination.ril100Ids,
            leg.origin.ril100Ids,
          )) {
        shouldCountInterchange = true;
      } else if (previousLeg.destination.id != leg.origin.id ||
          previousLeg.destination.name != leg.origin.name) {
        shouldCountInterchange = true;
      }

      if (shouldCountInterchange) interchangeCount++;
    }

    return interchangeCount;
  }

  bool haveSameRil100ID(List<String> ids1, List<String> ids2) {
    if (ids1.isEmpty || ids2.isEmpty) return false;
    for (String id1 in ids1) {
      for (String id2 in ids2) {
        if (id1 == id2) return true;
      }
    }
    return false;
  }
}