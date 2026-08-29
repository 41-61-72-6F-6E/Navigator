import 'package:flutter_test/flutter_test.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

void main() {
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
