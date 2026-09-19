import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/subway_line.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

void main() {
  group('transit map loading', () {
    test('publishes stations before a slow line request finishes', () async {
      final linesCompleter = Completer<List<SubwayLine>>();
      var lineCalls = 0;
      var stationCalls = 0;
      final model = HomePageModel(
        page: HomePageIni(),
        services: ServicesMiddle(),
        loadTransitLines: ({required lat, required lon, required radius}) {
          lineCalls++;
          return linesCompleter.future;
        },
        loadTransitStations:
            ({required lat, required lon, required radius}) async {
              stationCalls++;
              return [_station('station', 'Station')];
            },
      );
      addTearDown(model.dispose);

      final load = model.loadMapOverlaysAt(const LatLng(52.5, 13.4));
      await Future<void>.delayed(Duration.zero);

      expect(model.layers.stations, hasLength(1));
      expect(model.layers.lines, isEmpty);
      expect(model.layers.isOverlayLoading, isTrue);

      model.resumeMapDataLoading();
      expect(stationCalls, 1);
      expect(lineCalls, 1);

      linesCompleter.complete([]);
      await load;
      expect(model.layers.isOverlayLoading, isFalse);
    });

    test('resolves location once and loads each overlay once', () async {
      var locationCalls = 0;
      var lineCalls = 0;
      var stationCalls = 0;
      int? lineRadius;
      int? stationRadius;

      final model = HomePageModel(
        page: HomePageIni(),
        services: ServicesMiddle(),
        getCurrentLocation: () async {
          locationCalls++;
          return Location(
            backend: 'test',
            type: 'location',
            id: 'current',
            name: 'Current location',
            latitude: 52.5,
            longitude: 13.4,
          );
        },
        loadTransitLines:
            ({required lat, required lon, required radius}) async {
              lineCalls++;
              lineRadius = radius;
              expect(lat, 52.5);
              expect(lon, 13.4);
              return [
                SubwayLine(
                  backend: 'OSM',
                  points: const [LatLng(52.5, 13.4), LatLng(52.51, 13.41)],
                  color: Colors.red,
                  type: 'tram',
                ),
              ];
            },
        loadTransitStations:
            ({required lat, required lon, required radius}) async {
              stationCalls++;
              stationRadius = radius;
              expect(lat, 52.5);
              expect(lon, 13.4);
              return [_station('station', 'Station')];
            },
      );
      addTearDown(model.dispose);

      await model.initializeMap();

      expect(locationCalls, 1);
      expect(lineCalls, 1);
      expect(stationCalls, 1);
      expect(lineRadius, HomePageModel.overlayRadiusMeters);
      expect(stationRadius, HomePageModel.overlayRadiusMeters);
      expect(model.layers.tramLines, hasLength(1));
      expect(model.layers.stations, hasLength(1));
      expect(model.layers.overlayError, isNull);
      expect(model.layers.isOverlayLoading, isFalse);
    });

    test('keeps a successful overlay when the other request fails', () async {
      final model = HomePageModel(
        page: HomePageIni(),
        services: ServicesMiddle(),
        getCurrentLocation: () async => Location(
          backend: 'test',
          type: 'location',
          id: 'current',
          name: 'Current location',
          latitude: 52.5,
          longitude: 13.4,
        ),
        loadTransitLines:
            ({required lat, required lon, required radius}) async =>
                throw Exception('lines offline'),
        loadTransitStations:
            ({required lat, required lon, required radius}) async => [
              _station('station', 'Station'),
            ],
      );
      addTearDown(model.dispose);

      await model.initializeMap();

      expect(model.layers.lines, isEmpty);
      expect(model.layers.stations, hasLength(1));
      expect(model.layers.overlayError, contains('lines offline'));
      expect(model.layers.isOverlayLoading, isFalse);
    });
  });

  group('ongoing journey sync', () {
    test(
      'periodically refreshes and removes a journey after it ends',
      () async {
        final now = DateTime.utc(2026, 8, 29, 12);
        final savedJourney = Savedjourney(
          journey: _journey(
            departure: now.subtract(const Duration(minutes: 10)),
            arrival: now.add(const Duration(minutes: 10)),
          ),
          id: 'saved-journey',
        );
        var refreshedJourney = savedJourney.journey;
        var refreshCount = 0;

        final model = HomePageModel(
          page: HomePageIni(),
          services: ServicesMiddle(),
          ongoingJourneySyncInterval: const Duration(milliseconds: 20),
          loadSavedJourneys: () async => [savedJourney],
          refreshJourneyByToken: (_) async {
            refreshCount++;
            return refreshedJourney;
          },
          now: () => now,
        );
        addTearDown(model.dispose);

        await model.initializeOngoingJourney();
        expect(model.journey.ongoingJourney?.journey, same(refreshedJourney));
        expect(refreshCount, 1);

        refreshedJourney = _journey(
          departure: now.subtract(const Duration(minutes: 10)),
          arrival: now.add(const Duration(minutes: 20)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(refreshCount, greaterThan(1));
        expect(model.journey.ongoingJourney?.journey, same(refreshedJourney));

        refreshedJourney = _journey(
          departure: now.subtract(const Duration(minutes: 20)),
          arrival: now.subtract(const Duration(minutes: 1)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(model.journey.ongoingJourney, isNull);
        expect(model.journey.legIndexToTripMap, isEmpty);
        expect(model.journey.polylines, isEmpty);
      },
    );

    test('keeps an active journey visible when a refresh fails', () async {
      final now = DateTime.utc(2026, 8, 29, 12);
      final savedJourney = Savedjourney(
        journey: _journey(
          departure: now.subtract(const Duration(minutes: 10)),
          arrival: now.add(const Duration(minutes: 10)),
        ),
        id: 'saved-journey',
      );

      final model = HomePageModel(
        page: HomePageIni(),
        services: ServicesMiddle(),
        ongoingJourneySyncInterval: const Duration(hours: 1),
        loadSavedJourneys: () async => [savedJourney],
        refreshJourneyByToken: (_) async => throw Exception('offline'),
        now: () => now,
      );
      addTearDown(model.dispose);

      await model.initializeOngoingJourney();

      expect(model.journey.ongoingJourney?.journey, same(savedJourney.journey));
    });

    test('does not start a journey before its real-time departure', () async {
      final now = DateTime.utc(2026, 8, 29, 12);
      final savedJourney = Savedjourney(
        journey: _journey(
          departure: now.add(const Duration(minutes: 5)),
          plannedDeparture: now.subtract(const Duration(minutes: 10)),
          arrival: now.add(const Duration(minutes: 30)),
        ),
        id: 'delayed-journey',
      );

      final model = HomePageModel(
        page: HomePageIni(),
        services: ServicesMiddle(),
        ongoingJourneySyncInterval: const Duration(hours: 1),
        loadSavedJourneys: () async => [savedJourney],
        refreshJourneyByToken: (_) async => savedJourney.journey,
        now: () => now,
      );
      addTearDown(model.dispose);

      await model.initializeOngoingJourney();

      expect(model.journey.ongoingJourney, isNull);
    });
  });

  group('ongoing journey progress', () {
    test('uses real-time leg times across a delayed interchange', () {
      final journey = Journey(
        backend: 'dbRest',
        refreshToken: 'refresh-token',
        legs: [
          _leg(
            id: 'first',
            plannedDeparture: DateTime.utc(2026, 8, 29, 11),
            departure: DateTime.utc(2026, 8, 29, 11, 10),
            plannedArrival: DateTime.utc(2026, 8, 29, 11, 30),
            arrival: DateTime.utc(2026, 8, 29, 11, 50),
          ),
          _leg(
            id: 'second',
            plannedDeparture: DateTime.utc(2026, 8, 29, 11, 35),
            departure: DateTime.utc(2026, 8, 29, 11, 55),
            plannedArrival: DateTime.utc(2026, 8, 29, 12),
            arrival: DateTime.utc(2026, 8, 29, 12, 20),
          ),
        ],
      );

      final onFirstLeg = journey.progressAt(DateTime.utc(2026, 8, 29, 11, 40));
      expect(onFirstLeg.currentLegIndex, 0);
      expect(onFirstLeg.isAfterCurrentLegArrival, isFalse);

      final atInterchange = journey.progressAt(
        DateTime.utc(2026, 8, 29, 11, 52),
      );
      expect(atInterchange.currentLegIndex, 0);
      expect(atInterchange.isAfterCurrentLegArrival, isTrue);

      final onSecondLeg = journey.progressAt(DateTime.utc(2026, 8, 29, 11, 56));
      expect(onSecondLeg.currentLegIndex, 1);
      expect(onSecondLeg.isAfterCurrentLegArrival, isFalse);
    });
  });
}

Journey _journey({
  required DateTime departure,
  DateTime? plannedDeparture,
  required DateTime arrival,
}) {
  return Journey(
    backend: 'dbRest',
    refreshToken: 'refresh-token',
    legs: [
      _leg(
        id: 'journey',
        departure: departure,
        plannedDeparture: plannedDeparture ?? departure,
        arrival: arrival,
        plannedArrival: arrival,
        isWalking: true,
      ),
    ],
  );
}

Leg _leg({
  required String id,
  required DateTime plannedDeparture,
  required DateTime plannedArrival,
  DateTime? departure,
  DateTime? arrival,
  bool? isWalking,
}) {
  return Leg(
    backend: 'dbRest',
    origin: _station('$id-origin', '$id Origin'),
    departure: departure?.toIso8601String(),
    plannedDeparture: plannedDeparture.toIso8601String(),
    destination: _station('$id-destination', '$id Destination'),
    arrival: arrival?.toIso8601String(),
    plannedArrival: plannedArrival.toIso8601String(),
    lineName: id,
    product: 'train',
    isWalking: isWalking,
    stopovers: const [],
  );
}

Station _station(String id, String name) {
  return Station(
    backend: 'dbRest',
    type: 'station',
    id: id,
    name: name,
    latitude: 52.5,
    longitude: 13.4,
    nationalExpress: false,
    national: false,
    regional: false,
    regionalExpress: false,
    suburban: false,
    bus: false,
    ferry: false,
    subway: false,
    tram: false,
    taxi: false,
    ril100Ids: const [],
  );
}
