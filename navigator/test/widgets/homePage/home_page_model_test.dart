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
  });
}

Journey _journey({required DateTime departure, required DateTime arrival}) {
  return Journey(
    backend: 'dbRest',
    refreshToken: 'refresh-token',
    legs: [
      Leg(
        backend: 'dbRest',
        origin: _station('origin', 'Origin'),
        plannedDeparture: departure.toIso8601String(),
        destination: _station('destination', 'Destination'),
        plannedArrival: arrival.toIso8601String(),
        isWalking: true,
        stopovers: const [],
      ),
    ],
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
