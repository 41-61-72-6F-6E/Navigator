import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/UIComponents/markerLayer/homePageMarkerLayerAndroid.dart';

void main() {
  group('station transfer classification', () {
    test('a stop with one transit product is regular', () {
      final station = _station(tram: true);

      expect(station.transitProductCount, 1);
      expect(station.isTransferStation, isFalse);
    });

    test('a station with multiple transit products is a transfer station', () {
      final station = _station(subway: true, tram: true);

      expect(station.transitProductCount, 2);
      expect(station.isTransferStation, isTrue);
    });

    test('taxi availability does not turn a stop into a transfer station', () {
      final station = _station(tram: true, taxi: true);

      expect(station.transitProductCount, 1);
      expect(station.isTransferStation, isFalse);
    });
  });

  group('home page station marker', () {
    testWidgets('regular stops use a compact dot', (tester) async {
      await tester.pumpWidget(
        _testApp(
          HomePageStationMarkerSymbol(
            station: _station(tram: true),
            transportIcon: Icons.tram,
            currentZoom: 15,
          ),
        ),
      );

      final marker = find.byKey(HomePageStationMarkerSymbol.regularMarkerKey);
      expect(marker, findsOneWidget);
      expect(tester.getSize(marker), const Size.square(12));
      expect(find.byIcon(Icons.tram), findsNothing);
    });

    testWidgets('transfer stations use a larger outlined mode marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          HomePageStationMarkerSymbol(
            station: _station(subway: true, tram: true),
            transportIcon: Icons.subway,
            currentZoom: 15,
          ),
        ),
      );

      final marker = find.byKey(HomePageStationMarkerSymbol.transferMarkerKey);
      expect(marker, findsOneWidget);
      expect(tester.getSize(marker), const Size.square(26));
      expect(find.byIcon(Icons.subway), findsOneWidget);
    });
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

Station _station({
  bool nationalExpress = false,
  bool national = false,
  bool regional = false,
  bool regionalExpress = false,
  bool suburban = false,
  bool bus = false,
  bool ferry = false,
  bool subway = false,
  bool tram = false,
  bool taxi = false,
}) {
  return Station(
    backend: 'OSM',
    type: 'station',
    id: 'station',
    name: 'Test Station',
    latitude: 52.5,
    longitude: 13.4,
    nationalExpress: nationalExpress,
    national: national,
    regional: regional,
    regionalExpress: regionalExpress,
    suburban: suburban,
    bus: bus,
    ferry: ferry,
    subway: subway,
    tram: tram,
    taxi: taxi,
    ril100Ids: const [],
  );
}
