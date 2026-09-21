import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_geojson.dart';

void main() {
  test('serializes map lines in longitude-latitude order', () {
    final json =
        jsonDecode(
              MapGeoJson.lines(const [
                NavigatorMapLine(
                  id: 'route',
                  points: [LatLng(52.5, 13.4), LatLng(52.6, 13.5)],
                  color: Colors.red,
                  width: 4,
                  dashed: true,
                ),
              ]),
            )
            as Map<String, dynamic>;

    final feature = json['features'][0] as Map<String, dynamic>;
    expect(feature['geometry']['coordinates'], [
      [13.4, 52.5],
      [13.5, 52.6],
    ]);
    expect(feature['properties']['dashed'], isTrue);
    expect(feature['properties']['color'], '#f44336ff');
  });

  test('serializes point styling and interaction properties', () {
    final json =
        jsonDecode(
              MapGeoJson.mapPoints(const [
                NavigatorMapPoint(
                  id: 'station',
                  point: LatLng(52.5, 13.4),
                  color: Colors.blue,
                  strokeColor: Colors.white,
                  label: 'Central',
                  showLabel: true,
                  properties: {'featureKey': 'station-key'},
                ),
              ]),
            )
            as Map<String, dynamic>;

    final feature = json['features'][0] as Map<String, dynamic>;
    expect(feature['geometry']['coordinates'], [13.4, 52.5]);
    expect(feature['properties']['label'], 'Central');
    expect(feature['properties']['showLabel'], isTrue);
    expect(feature['properties']['featureKey'], 'station-key');
  });
}
