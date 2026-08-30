import 'package:flutter_test/flutter_test.dart';
import 'package:navigator/models/departureArrival.dart';

void main() {
  test('keeps a cancelled departure that has no real-time value', () {
    final departure = DepartureArrival.fromJson('dbRest', {
      'stop': null,
      'station': _stationJson,
      'when': null,
      'plannedWhen': '2026-08-30T12:15:00+02:00',
      'cancelled': true,
      'line': {
        'name': 'RE 1',
        'operator': {'name': 'DB Regio'},
      },
    }, isDeparture: true);

    expect(departure.cancelled, isTrue);
    expect(departure.when, departure.plannedWhen);
    expect(departure.line?.operator?.name, 'DB Regio');
  });

  test('parses a string operator into the Operator model', () {
    final departure = DepartureArrival.fromJson('dbRest', {
      'stop': null,
      'station': _stationJson,
      'when': '2026-08-30T12:15:00+02:00',
      'plannedWhen': '2026-08-30T12:15:00+02:00',
      'cancelled': false,
      'line': {
        'name': 'RE 1',
        'operator': 'DB Regio',
      },
    }, isDeparture: true);

    expect(departure.line?.operator?.name, 'DB Regio');
  });
}

final Map<String, dynamic> _stationJson = {
  'type': 'station',
  'id': 'station-id',
  'name': 'Test Station',
  'location': {'latitude': 52.5, 'longitude': 13.4},
  'products': {
    'nationalExpress': false,
    'national': false,
    'regional': true,
    'regionalExpress': false,
    'suburban': true,
    'bus': true,
    'ferry': false,
    'subway': false,
    'tram': false,
    'taxi': false,
  },
};
