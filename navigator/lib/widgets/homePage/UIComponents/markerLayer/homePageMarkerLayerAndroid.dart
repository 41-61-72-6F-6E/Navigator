import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class HomePageMarkerLayerAndroid extends StatelessWidget {
  final HomePageModel model;
  final String transportType;

  const HomePageMarkerLayerAndroid({
    super.key,
    required this.model,
    required this.transportType,
  });

  @override
  Widget build(BuildContext context) {
    final state = model.state;
    if (!model.getShowLabels(transportType) || state.currentZoom <= 12) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;

    final markers = state.stations
        .where((station) {
          if (!model.shouldShowStation(station, transportType)) return false;
          final minZoom = model.getMinZoomForStation(station);
          if (state.currentZoom < minZoom) return false;
          return true;
        })
        .fold<Map<String, Station>>({}, (map, station) {
          if (state.currentZoom <= 15.5 && !map.containsKey(station.name)) {
            map[station.name] = station;
          } else if (state.currentZoom > 15.5) {
            map["${station.name}_${station.latitude}_${station.longitude}"] = station;
          }
          return map;
        })
        .values
        .fold<Map<String, List<Station>>>({}, (collisionMap, station) {
          if (state.currentZoom > 16.5) {
            final uniqueKey = "${station.name}_${station.latitude}_${station.longitude}";
            collisionMap[uniqueKey] = [station];
          } else {
            final key = model.getLabelCollisionKey(station, state.currentZoom);
            if (!collisionMap.containsKey(key)) collisionMap[key] = [];
            collisionMap[key]!.add(station);
          }
          return collisionMap;
        })
        .entries
        .expand((entry) {
          final stations = entry.value;
          if (stations.length > 1 && state.currentZoom <= 17) {
            final uniqueByName = <String, Station>{};
            for (final s in stations) uniqueByName[s.name] = s;
            return uniqueByName.values;
          }
          return stations;
        })
        .map((station) {
          return Marker(
            point: LatLng(station.latitude, station.longitude),
            width: 150,
            height: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.currentZoom > 15.5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (state.currentZoom > 14.5) const SizedBox(height: 2),
                Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(state.currentZoom > 14 ? 4 : 3),
                  child: Icon(
                    model.getTransportIcon(station),
                    color: colors.onPrimary,
                    size: state.currentZoom > 14 ? 14 : 12,
                  ),
                ),
              ],
            ),
          );
        })
        .toList();

    return MarkerLayer(markers: markers);
  }
}