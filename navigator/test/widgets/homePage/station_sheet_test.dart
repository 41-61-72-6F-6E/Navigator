import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/models/line.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/stationSheetAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

void main() {
  testWidgets('shows station information and real-time departures', (
    tester,
  ) async {
    final completer = Completer<List<DepartureArrival>>();
    final model = _model();
    addTearDown(model.dispose);

    await tester.pumpWidget(
      _testApp(
        StationSheetAndroid(
          model: model,
          station: _station,
          departureLoader: (_) => completer.future,
        ),
      ),
    );

    expect(find.byKey(StationSheetAndroid.loadingKey), findsOneWidget);
    expect(find.text('Berlin Hbf'), findsOneWidget);
    expect(find.text('S-Bahn'), findsOneWidget);
    expect(find.text('Next departures'), findsOneWidget);

    completer.complete([
      _departure(
        line: 'RE 1',
        direction: 'Frankfurt (Oder)',
        delay: 300,
        platform: '12',
      ),
      _departure(line: 'ICE 100', direction: 'Hamburg Hbf', cancelled: true),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(StationSheetAndroid.departuresKey), findsOneWidget);
    expect(find.text('RE 1'), findsOneWidget);
    expect(find.text('Frankfurt (Oder)'), findsOneWidget);
    expect(find.text('+5 min'), findsOneWidget);
    expect(find.text('Platform 12'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('offers a retry when departures cannot be loaded', (
    tester,
  ) async {
    final model = _model();
    addTearDown(model.dispose);
    var attempts = 0;

    await tester.pumpWidget(
      _testApp(
        StationSheetAndroid(
          model: model,
          station: _station,
          departureLoader: (_) async {
            attempts++;
            if (attempts == 1) throw Exception('offline');
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(StationSheetAndroid.errorKey), findsOneWidget);
    expect(find.text('Departures unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(StationSheetAndroid.emptyKey), findsOneWidget);
    expect(find.text('No upcoming departures'), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(height: 700, child: child)),
  );
}

HomePageModel _model() {
  return HomePageModel(page: HomePageIni(), services: ServicesMiddle());
}

final Station _station = Station(
  backend: 'dbRest',
  type: 'station',
  id: '8011160',
  name: 'Berlin Hbf',
  latitude: 52.525,
  longitude: 13.369,
  nationalExpress: true,
  national: true,
  regional: true,
  regionalExpress: true,
  suburban: true,
  bus: true,
  ferry: false,
  subway: false,
  tram: true,
  taxi: true,
  ril100Ids: const ['BLS'],
);

DepartureArrival _departure({
  required String line,
  required String direction,
  int? delay,
  String? platform,
  bool cancelled = false,
}) {
  final planned = DateTime.utc(2026, 8, 30, 10);
  return DepartureArrival(
    backend: 'dbRest',
    station: _station,
    when: planned.add(Duration(seconds: delay ?? 0)),
    plannedWhen: planned,
    delay: delay,
    platform: platform,
    direction: direction,
    line: Line(backend: 'dbRest', name: line),
    isDeparture: true,
    cancelled: cancelled,
  );
}
