import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
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

    test('removes the transit layer and filters general POI layers', () {
      final source = const vt.ThemeReader().read({
        'id': 'test-theme',
        'layers': [
          {
            'id': 'roads',
            'type': 'line',
            'source': 'openmaptiles',
            'source-layer': 'transportation',
          },
          {
            'id': 'poi_r1',
            'type': 'symbol',
            'source': 'openmaptiles',
            'source-layer': 'poi',
            'filter': [
              'match',
              ['geometry-type'],
              ['Point', 'MultiPoint'],
              true,
              false,
            ],
            'layout': {
              'text-field': ['get', 'name'],
            },
          },
          {
            'id': 'poi_transit',
            'type': 'symbol',
            'source': 'openmaptiles',
            'source-layer': 'poi',
          },
        ],
      });

      final curated = CuratedMapTheme.curate(source);

      expect(curated.id, endsWith('-navigator-pois-v1'));
      expect(curated.layers.map((layer) => layer.id), ['roads', 'poi_r1']);
      expect(identical(curated.layers.first, source.layers.first), isTrue);

      final poiLayer = curated.layers.last as vt.SymbolThemeLayer;
      expect(poiLayer.matches(_feature('restaurant')), isTrue);
      expect(poiLayer.matches(_feature('waste_basket')), isFalse);
      expect(poiLayer.matches(_feature('rail')), isFalse);
      expect(
        poiLayer.matches(_feature('restaurant', geometryType: 'LineString')),
        isFalse,
      );
      expect(poiLayer.referencedProperties, containsAll(['class', 'subclass']));
    });
  });
}

vt.EvalContext _feature(String poiClass, {String geometryType = 'Point'}) {
  return vt.EvalContext(
    zoom: 17,
    geometryType: geometryType,
    properties: {'class': poiClass, 'subclass': poiClass, 'name': 'Test'},
  );
}
