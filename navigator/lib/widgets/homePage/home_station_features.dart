import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class HomeStationFeatures {
  final List<NavigatorMapPoint> points;
  final Map<String, Station> stationsByKey;

  const HomeStationFeatures({
    required this.points,
    required this.stationsByKey,
  });
}

HomeStationFeatures buildHomeStationFeatures(
  HomePageModel model,
  ColorScheme colors,
) {
  final layers = model.layers;
  final zoom = model.position.currentZoom;

  bool isVisible(Station station) {
    if (zoom < model.getMinZoomForStation(station)) return false;
    if (model.shouldShowStation(station, 'rail') &&
        model.getShowLabels('rail')) {
      return true;
    }
    if (layers.showLightRail &&
        layers.showStationLabelsLightRail &&
        model.shouldShowStation(station, 'lightRail')) {
      return true;
    }
    if (layers.showSubway &&
        layers.showStationLabelsSubway &&
        model.shouldShowStation(station, 'subway')) {
      return true;
    }
    if (layers.showTram &&
        layers.showStationLabelsTram &&
        model.shouldShowStation(station, 'tram')) {
      return true;
    }
    if (layers.showFerry &&
        layers.showStationLabelsFerry &&
        model.shouldShowStation(station, 'ferry')) {
      return true;
    }
    return false;
  }

  final byName = <String, Station>{};
  for (final station in layers.stations.where(isVisible)) {
    final key = zoom <= 15.5
        ? station.name
        : '${station.name}_${station.latitude}_${station.longitude}';
    byName.putIfAbsent(key, () => station);
  }

  final collisionGroups = <String, List<Station>>{};
  for (final station in byName.values) {
    final key = zoom > 16.5
        ? '${station.name}_${station.latitude}_${station.longitude}'
        : model.getLabelCollisionKey(station, zoom);
    collisionGroups.putIfAbsent(key, () => []).add(station);
  }

  final visibleStations = <Station>[];
  for (final group in collisionGroups.values) {
    if (group.length > 1 && zoom <= 17) {
      visibleStations.addAll(
        {for (final station in group) station.name: station}.values,
      );
    } else {
      visibleStations.addAll(group);
    }
  }

  final stationsByKey = <String, Station>{};
  final points = <NavigatorMapPoint>[];
  for (final station in visibleStations) {
    final key = '${station.id}:${station.latitude}:${station.longitude}';
    stationsByKey[key] = station;
    final transfer = station.isTransferStation;
    points.add(
      NavigatorMapPoint(
        id: 'station-$key',
        point: LatLng(station.latitude, station.longitude),
        label: station.name,
        showLabel: zoom > 15.5,
        labelColor: colors.onSurfaceVariant,
        labelHaloColor: colors.surfaceContainer,
        color: transfer ? colors.surface : colors.primary,
        strokeColor: transfer ? colors.primary : colors.surface,
        radius: transfer ? (zoom > 14 ? 13 : 11) : (zoom > 14 ? 6 : 5),
        strokeWidth: transfer ? 3 : 1.5,
        icon: transfer ? 'navigator-transit' : '',
        iconSize: zoom > 14 ? 0.08 : 0.07,
        properties: {'featureKey': key, 'kind': 'station'},
      ),
    );
  }

  return HomeStationFeatures(points: points, stationsByKey: stationsByKey);
}
