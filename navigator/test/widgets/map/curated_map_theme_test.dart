import 'package:flutter_test/flutter_test.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/curated_map_theme.dart';

void main() {
  group('CuratedMapTheme POI policy', () {
    test('keeps useful journey destinations', () {
      const useful = [
        {'class': 'restaurant'},
        {'class': 'grocery'},
        {'class': 'hospital'},
        {'class': 'toilets'},
        {'class': 'lodging'},
        {'class': 'museum'},
        {'class': 'park'},
        {'class': 'shop', 'subclass': 'convenience'},
        {'class': 'post', 'subclass': 'post_office'},
      ];

      for (final properties in useful) {
        expect(
          CuratedMapTheme.isUsefulPoi(properties),
          isTrue,
          reason: '$properties should remain visible',
        );
      }
    });

    test('hides duplicate transit and low-value street furniture', () {
      const hidden = [
        {'class': 'rail', 'subclass': 'station'},
        {'class': 'bus', 'subclass': 'bus_stop'},
        {'class': 'entrance', 'subclass': 'subway_entrance'},
        {'class': 'waste_basket'},
        {'class': 'recycling'},
        {'class': 'bench'},
        {'class': 'bicycle_parking'},
        {'class': 'barrier', 'subclass': 'bollard'},
        {'class': 'office'},
        {'class': 'unknown_future_category'},
      ];

      for (final properties in hidden) {
        expect(
          CuratedMapTheme.isUsefulPoi(properties),
          isFalse,
          reason: '$properties should be hidden',
        );
      }
    });

    test('removes transit POIs and filters general POI layers', () {
      final roads = <String, dynamic>{
        'id': 'roads',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
      };
      final existingFilter = <dynamic>[
        'match',
        ['geometry-type'],
        ['Point', 'MultiPoint'],
        true,
        false,
      ];
      final source = <String, dynamic>{
        'version': 8,
        'layers': [
          roads,
          {
            'id': 'poi_r1',
            'type': 'symbol',
            'source': 'openmaptiles',
            'source-layer': 'poi',
            'filter': existingFilter,
          },
          {
            'id': 'poi_transit',
            'type': 'symbol',
            'source': 'openmaptiles',
            'source-layer': 'poi',
          },
        ],
      };

      final curated = CuratedMapTheme.curate(source);
      final layers = curated['layers']! as List<dynamic>;

      expect(layers.map((layer) => layer['id']), ['roads', 'poi_r1']);
      expect(identical(layers.first, roads), isFalse);
      final filter = layers.last['filter'] as List<dynamic>;
      expect(filter.first, 'all');
      expect(filter[1], existingFilter);
      expect(filter[2], isA<List<dynamic>>());
      expect(source['layers'], hasLength(3), reason: 'input is not mutated');
    });
  });
}
