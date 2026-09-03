import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

/// Reduces the base map to POIs that help someone plan or interrupt a journey.
///
/// The OpenFreeMap Bright style renders the complete OpenMapTiles `poi` layer,
/// which includes transit stops already drawn by Navigator as well as street
/// furniture such as waste baskets and benches. Keeping an allowlist makes new
/// or unknown POI classes hidden by default instead of gradually adding noise.
abstract final class CuratedMapTheme {
  static const Set<String> usefulPoiClasses = {
    // Food and everyday supplies.
    'restaurant',
    'cafe',
    'fast_food',
    'ice_cream',
    'beer',
    'bar',
    'bakery',
    'grocery',

    // Accommodation.
    'lodging',
    'campsite',

    // Health and urgent help.
    'hospital',
    'pharmacy',
    'doctors',
    'dentist',
    'clinic',
    'police',
    'fire_station',

    // Useful during a journey.
    'toilets',
    'drinking_water',
    'atm',
    'bank',
    'fuel',
    'charging_station',
    'bicycle_rental',
    'car_rental',
    'laundry',

    // Destinations, culture, and recreation.
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

  /// Useful specializations whose broader class is intentionally hidden.
  /// For example, post offices are useful but individual post boxes are not.
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

  static const Set<String> _removedLayerIds = {'poi_transit'};

  static bool isUsefulPoi(Map<String, Object?> properties) {
    final poiClass = properties['class']?.toString();
    final subclass = properties['subclass']?.toString();
    return usefulPoiClasses.contains(poiClass) ||
        usefulPoiSubclasses.contains(subclass);
  }

  static vt.Theme curate(vt.Theme source) {
    final layers = <vt.ThemeLayer>[];
    for (final layer in source.layers) {
      if (_removedLayerIds.contains(layer.id)) continue;

      if (layer is vt.SymbolThemeLayer && layer.sourceLayer == 'poi') {
        layers.add(_curatePoiLayer(layer));
      } else {
        layers.add(layer);
      }
    }

    return vt.Theme(id: '${source.id}-navigator-pois-v1', layers: layers);
  }

  static vt.SymbolThemeLayer _curatePoiLayer(vt.SymbolThemeLayer source) {
    final layer = vt.SymbolThemeLayer(
      id: source.id,
      source: source.source,
      sourceLayer: source.sourceLayer,
      minzoom: source.minzoom,
      maxzoom: source.maxzoom,
      filter: (context) =>
          source.matches(context) && isUsefulPoi(context.properties),
      placement: source.placement,
      sortKey: source.sortKey,
      spacing: source.spacing,
      textField: source.textField,
      textSize: source.textSize,
      textFont: source.textFont,
      textMaxWidth: source.textMaxWidth,
      textLetterSpacing: source.textLetterSpacing,
      textTransform: source.textTransform,
      textAnchor: source.textAnchor,
      textVariableAnchor: source.textVariableAnchor,
      textRadialOffset: source.textRadialOffset,
      textOffset: source.textOffset,
      textPadding: source.textPadding,
      textAllowOverlap: source.textAllowOverlap,
      textOptional: source.textOptional,
      textMaxAngle: source.textMaxAngle,
      textKeepUpright: source.textKeepUpright,
      textRotationAlignment: source.textRotationAlignment,
      iconImage: source.iconImage,
      iconSize: source.iconSize,
      iconAnchor: source.iconAnchor,
      iconOffset: source.iconOffset,
      iconAllowOverlap: source.iconAllowOverlap,
      textColor: source.textColor,
      textHaloColor: source.textHaloColor,
      textHaloWidth: source.textHaloWidth,
      textOpacity: source.textOpacity,
      iconOpacity: source.iconOpacity,
      iconColor: source.iconColor,
      iconHaloColor: source.iconHaloColor,
      iconHaloWidth: source.iconHaloWidth,
    );
    layer.referencedProperties = {
      ...?source.referencedProperties,
      'class',
      'subclass',
    };
    return layer;
  }
}
