import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';

ml.Geographic toGeographic(LatLng point) =>
    ml.Geographic(lon: point.longitude, lat: point.latitude);

LatLng fromGeographic(ml.Geographic point) => LatLng(point.lat, point.lon);

class MapLibreCamera implements NavigatorMapCamera {
  final ml.MapController controller;

  const MapLibreCamera(this.controller);

  @override
  Future<void> moveTo(LatLng center, double zoom) {
    return controller.moveCamera(center: toGeographic(center), zoom: zoom);
  }

  @override
  Future<void> animateTo(
    LatLng center,
    double zoom, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return controller.animateCamera(
      center: toGeographic(center),
      zoom: zoom,
      nativeDuration: duration,
      webMaxDuration: duration,
    );
  }
}
