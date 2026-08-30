import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:navigator/services/overpassApi.dart';

void main() {
  group('Overpassapi', () {
    test('falls back to another endpoint and parses area stations', () async {
      final requestedHosts = <String>[];
      final client = MockClient((request) async {
        requestedHosts.add(request.url.host);
        if (request.url.host == 'primary.test') {
          return http.Response('busy', 503);
        }
        return http.Response(jsonEncode(_stationResponse), 200);
      });
      final api = Overpassapi(
        client: client,
        endpoints: const [
          'https://primary.test/api/interpreter',
          'https://fallback.test/api/interpreter',
        ],
      );

      final stations = await api.fetchStationsByType(
        lat: 52.52,
        lon: 13.405,
        radius: 20000,
      );

      expect(requestedHosts, ['primary.test', 'fallback.test']);
      expect(stations, hasLength(2));
      expect(stations.first.name, 'Central');
      expect(stations.first.regional, isTrue);
      expect(stations.first.national, isFalse);
      expect(stations.last.name, 'Metro');
      expect(stations.last.latitude, 52.51);
      expect(stations.last.subway, isTrue);
      expect(stations.last.regional, isFalse);
    });

    test('returns stale nearby stations when every endpoint fails', () async {
      var now = DateTime.utc(2026, 8, 30, 10);
      var offline = false;
      final client = MockClient((request) async {
        if (offline) return http.Response('offline', 503);
        return http.Response(jsonEncode(_stationResponse), 200);
      });
      final api = Overpassapi(
        client: client,
        endpoints: const [
          'https://primary.test/api/interpreter',
          'https://fallback.test/api/interpreter',
        ],
        cacheTtl: const Duration(minutes: 5),
        now: () => now,
      );

      final initial = await api.fetchStationsByType(
        lat: 52.52,
        lon: 13.405,
        radius: 20000,
      );
      offline = true;
      now = now.add(const Duration(minutes: 6));

      final cached = await api.fetchStationsByType(
        lat: 52.52,
        lon: 13.405,
        radius: 20000,
      );

      expect(cached, same(initial));
    });

    test('serializes simultaneous line and station requests', () async {
      var activeRequests = 0;
      var maximumActiveRequests = 0;
      final client = MockClient((request) async {
        activeRequests++;
        if (activeRequests > maximumActiveRequests) {
          maximumActiveRequests = activeRequests;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        activeRequests--;
        return http.Response('{"elements":[]}', 200);
      });
      final api = Overpassapi(
        client: client,
        endpoints: const ['https://overpass.test/api/interpreter'],
      );

      await Future.wait([
        api.fetchSubwayLinesWithColors(lat: 52.52, lon: 13.405, radius: 20000),
        api.fetchStationsByType(lat: 52.52, lon: 13.405, radius: 20000),
      ]);

      expect(maximumActiveRequests, 1);
    });

    test('line responses retain relation metadata and way geometry', () {
      final api = Overpassapi(
        client: MockClient((_) async => http.Response('', 500)),
      );

      final lines = api.parseSubwayLinesFromOverpass({
        'elements': [
          {
            'type': 'relation',
            'id': 1,
            'tags': {
              'route': 'tram',
              'ref': 'M1',
              'name': 'Tram M1',
              'colour': '#cc0000',
            },
            'members': [
              {'type': 'way', 'ref': 2},
            ],
          },
          {
            'type': 'way',
            'id': 2,
            'geometry': [
              {'lat': 52.5, 'lon': 13.4},
              {'lat': 52.51, 'lon': 13.41},
            ],
          },
        ],
      });

      expect(lines, hasLength(1));
      expect(lines.single.type, 'tram');
      expect(lines.single.lineRef, 'M1');
      expect(lines.single.points, hasLength(2));
    });
  });
}

const _stationResponse = {
  'elements': [
    {
      'type': 'node',
      'id': 1,
      'lat': 52.5,
      'lon': 13.4,
      'tags': {'name': 'Central', 'railway': 'station'},
    },
    {
      'type': 'way',
      'id': 2,
      'center': {'lat': 52.51, 'lon': 13.41},
      'tags': {'name': 'Metro', 'station': 'subway'},
    },
  ],
};
