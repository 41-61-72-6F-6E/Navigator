import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/homePage/home_station_features.dart';

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

  group('home station map features', () {
    test('regular stops use a compact dot', () {
      final model = _modelAtZoom(15)
        ..layers.updateStations([_station(tram: true)]);
      addTearDown(model.dispose);

      final point = buildHomeStationFeatures(model, _colors).points.single;

      expect(point.radius, 6);
      expect(point.icon, isEmpty);
    });

    test('transfer stations use a larger mode marker', () {
      final model = _modelAtZoom(15)
        ..layers.updateStations([_station(subway: true, tram: true)]);
      addTearDown(model.dispose);

      final point = buildHomeStationFeatures(model, _colors).points.single;

      expect(point.radius, 13);
      expect(point.strokeWidth, 3);
      expect(point.icon, 'navigator-transit');
    });

    test('major rail stations are visible at the initial zoom', () {
      final model = _modelAtZoom(12)
        ..layers.updateStations([_station(national: true)]);
      addTearDown(model.dispose);

      expect(buildHomeStationFeatures(model, _colors).points, hasLength(1));
    });
  });
}

final _colors = ColorScheme.fromSeed(seedColor: Colors.blue);

HomePageModel _modelAtZoom(double zoom) {
  return HomePageModel(page: HomePageIni(), services: ServicesMiddle())
    ..position.update(currentZoom: zoom);
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
