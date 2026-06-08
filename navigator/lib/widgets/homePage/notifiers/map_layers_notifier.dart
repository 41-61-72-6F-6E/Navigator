import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:navigator/models/station.dart';

class MapLayersNotifier extends ChangeNotifier {
  List<Polyline> lines;
  List<Polyline> subwayLines;
  List<Polyline> lightRailLines;
  List<Polyline> tramLines;
  List<Polyline> ferryLines;
  List<Polyline> funicularLines;
  List<Station> stations;

  bool showSubway;
  bool showLightRail;
  bool showTram;
  bool showFerry;
  bool showFunicular;

  bool showStationLabelsSubway;
  bool showStationLabelsLightRail;
  bool showStationLabelsTram;
  bool showStationLabelsFerry;
  bool showStationLabelsFunicular;

  MapLayersNotifier({
    this.lines = const [],
    this.subwayLines = const [],
    this.lightRailLines = const [],
    this.tramLines = const [],
    this.ferryLines = const [],
    this.funicularLines = const [],
    this.stations = const [],
    this.showSubway = true,
    this.showLightRail = true,
    this.showTram = true,
    this.showFerry = true,
    this.showFunicular = true,
    this.showStationLabelsSubway = true,
    this.showStationLabelsLightRail = true,
    this.showStationLabelsTram = true,
    this.showStationLabelsFerry = true,
    this.showStationLabelsFunicular = true,
  });

  void updateLines({
    List<Polyline>? lines,
    List<Polyline>? subwayLines,
    List<Polyline>? lightRailLines,
    List<Polyline>? tramLines,
    List<Polyline>? ferryLines,
    List<Polyline>? funicularLines,
  }) {
    if (lines != null) this.lines = lines;
    if (subwayLines != null) this.subwayLines = subwayLines;
    if (lightRailLines != null) this.lightRailLines = lightRailLines;
    if (tramLines != null) this.tramLines = tramLines;
    if (ferryLines != null) this.ferryLines = ferryLines;
    if (funicularLines != null) this.funicularLines = funicularLines;
    notifyListeners();
  }

  void updateStations(List<Station> stations) {
    this.stations = stations;
    notifyListeners();
  }

  void updateVisibility({
    bool? showSubway,
    bool? showLightRail,
    bool? showTram,
    bool? showFerry,
    bool? showFunicular,
    bool? showStationLabelsSubway,
    bool? showStationLabelsLightRail,
    bool? showStationLabelsTram,
    bool? showStationLabelsFerry,
    bool? showStationLabelsFunicular,
  }) {
    if (showSubway != null) this.showSubway = showSubway;
    if (showLightRail != null) this.showLightRail = showLightRail;
    if (showTram != null) this.showTram = showTram;
    if (showFerry != null) this.showFerry = showFerry;
    if (showFunicular != null) this.showFunicular = showFunicular;
    if (showStationLabelsSubway != null) this.showStationLabelsSubway = showStationLabelsSubway;
    if (showStationLabelsLightRail != null) this.showStationLabelsLightRail = showStationLabelsLightRail;
    if (showStationLabelsTram != null) this.showStationLabelsTram = showStationLabelsTram;
    if (showStationLabelsFerry != null) this.showStationLabelsFerry = showStationLabelsFerry;
    if (showStationLabelsFunicular != null) this.showStationLabelsFunicular = showStationLabelsFunicular;
    notifyListeners();
  }

  bool getShowLabels(String transportType) {
    switch (transportType) {
      case 'lightRail': return showStationLabelsLightRail;
      case 'subway': return showStationLabelsSubway;
      case 'tram': return showStationLabelsTram;
      case 'ferry': return showStationLabelsFerry;
      case 'funicular': return showStationLabelsFunicular;
      default: return false;
    }
  }
}