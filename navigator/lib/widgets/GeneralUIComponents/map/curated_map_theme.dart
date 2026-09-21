abstract final class CuratedMapTheme {
  static const Set<String> usefulPoiClasses = {
    'restaurant',
    'cafe',
    'fast_food',
    'ice_cream',
    'beer',
    'bar',
    'bakery',
    'grocery',
    'lodging',
    'campsite',
    'hospital',
    'pharmacy',
    'doctors',
    'dentist',
    'clinic',
    'police',
    'fire_station',
    'toilets',
    'drinking_water',
    'atm',
    'bank',
    'fuel',
    'charging_station',
    'bicycle_rental',
    'car_rental',
    'laundry',
    'attraction',
    'museum',
    'art_gallery',
    'castle',
    'monument',
    'memorial',
    'viewpoint',
    'zoo',
    'park',
    'stadium',
    'theatre',
    'cinema',
    'library',
    'information',
    'picnic_site',
    'town_hall',
  };

  static const Set<String> usefulPoiSubclasses = {
    'food_court',
    'biergarten',
    'pub',
    'supermarket',
    'convenience',
    'marketplace',
    'mall',
    'chemist',
    'post_office',
    'parcel_locker',
    'hotel',
    'motel',
    'bed_and_breakfast',
    'guest_house',
    'hostel',
    'camp_site',
    'caravan_site',
    'charging_station',
    'bicycle_rental',
    'car_rental',
    'arts_centre',
    'gallery',
    'artwork',
    'ruins',
    'viewpoint',
    'picnic_site',
  };

  static bool isUsefulPoi(Map<String, Object?> properties) {
    return usefulPoiClasses.contains(properties['class']) ||
        usefulPoiSubclasses.contains(properties['subclass']);
  }

  static Map<String, dynamic> curate(Map<String, dynamic> source) {
    final curated = Map<String, dynamic>.from(source);
    final sourceLayers = source['layers'] as List<dynamic>? ?? const [];
    final layers = <Map<String, dynamic>>[];

    for (final rawLayer in sourceLayers) {
      final layer = Map<String, dynamic>.from(rawLayer as Map);
      if (layer['id'] == 'poi_transit') continue;

      if (layer['source-layer'] == 'poi' && layer['type'] == 'symbol') {
        final existingFilter = layer['filter'];
        final usefulFilter = [
          'any',
          [
            'match',
            ['get', 'class'],
            usefulPoiClasses.toList()..sort(),
            true,
            false,
          ],
          [
            'match',
            ['get', 'subclass'],
            usefulPoiSubclasses.toList()..sort(),
            true,
            false,
          ],
        ];
        layer['filter'] = existingFilter == null
            ? usefulFilter
            : ['all', existingFilter, usefulFilter];
      }
      layers.add(layer);
    }

    curated['layers'] = layers;
    return curated;
  }
}
