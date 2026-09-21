import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/widgets/journeyPage/journeyPageModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reloads the journey using its refresh token', () async {
    final original = _journey('original-token', 'Original');
    final refreshed = _journey('refreshed-token', 'Refreshed');
    String? requestedToken;
    final page = JourneyPageIni(journey: original);
    final model = JourneyPageAndroidModel(
      page: page,
      journey: original,
      refreshJourneyByToken: (token) async {
        requestedToken = token;
        return refreshed;
      },
      positionStream: const Stream<Position>.empty(),
    );
    addTearDown(model.dispose);

    await model.reloadJourney();

    expect(requestedToken, 'original-token');
    expect(model.journey, same(refreshed));
    expect(page.journey, same(refreshed));
  });

  test('retains the current journey when reloading fails', () async {
    final original = _journey('original-token', 'Original');
    final page = JourneyPageIni(journey: original);
    final model = JourneyPageAndroidModel(
      page: page,
      journey: original,
      refreshJourneyByToken: (_) async => throw Exception('offline'),
      positionStream: const Stream<Position>.empty(),
    );
    addTearDown(model.dispose);

    await expectLater(model.reloadJourney(), throwsException);

    expect(model.journey, same(original));
    expect(page.journey, same(original));
  });
}

Journey _journey(String refreshToken, String name) {
  final departure = DateTime.utc(2026, 9, 21, 10);
  return Journey(
    backend: 'dbRest',
    refreshToken: refreshToken,
    legs: [
      Leg(
        backend: 'dbRest',
        origin: _station('$name Origin', 52.5, 13.4),
        plannedDeparture: departure.toIso8601String(),
        destination: _station('$name Destination', 52.6, 13.5),
        plannedArrival:
            departure.add(const Duration(hours: 1)).toIso8601String(),
        isWalking: true,
        stopovers: const [],
      ),
    ],
  );
}

Station _station(String name, double latitude, double longitude) {
  return Station(
    backend: 'dbRest',
    type: 'station',
    id: name,
    name: name,
    latitude: latitude,
    longitude: longitude,
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
