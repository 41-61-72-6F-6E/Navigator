import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/trip.dart';

class HomePageUIState {
  final List<Location> searchResults;
  final String lastSearchedText;
  final LatLng? currentUserLocation;
  final LatLng currentCenter;
  final double currentZoom;
  final List<Polyline> lines;
  final List<Station> stations;
  final Savedjourney? ongoingJourney;
  final List<Trip> tripsForOngoingJourneyLegs;
  final List<int> legsOfOngoingJourneyThatHaveATrip;
  final Map<int, Trip> legIndexToTripMap;
  final bool ongoingJourneyIntermediateStopsExpanded;
  final bool lowerBoxExpanded;
  final List<Polyline> ongoingJourneyPolylines;
  final Map<String, Color> ongoingJourneyTransitLineColorCache;
  final int? ongoingJourneyCurrentLegIndex;

  // Map Options
  final bool showLightRail;
  final bool showStationLabelsLightRail;
  final List<Polyline> lightRailLines;
  final bool showSubway;
  final bool showStationLabelsSubway;
  final List<Polyline> subwayLines;
  final bool showTram;
  final bool showStationLabelsTram;
  final List<Polyline> tramLines;
  final bool showFerry;
  final bool showStationLabelsFerry;
  final List<Polyline> ferryLines;
  final bool showFunicular;
  final bool showStationLabelsFunicular;
  final List<Polyline> funicularLines;

  final AlignOnUpdate alignPositionOnUpdate;
  final List<FavoriteLocation> faves;
  final bool ongoingJourneyOnMap;

  const HomePageUIState({
    this.searchResults = const [],
    this.lastSearchedText = '',
    this.currentUserLocation,
    LatLng? currentCenter,
    this.currentZoom = 10,
    this.lines = const [],
    this.stations = const [],
    this.ongoingJourney,
    this.tripsForOngoingJourneyLegs = const [],
    this.legsOfOngoingJourneyThatHaveATrip = const [],
    this.legIndexToTripMap = const {},
    this.ongoingJourneyIntermediateStopsExpanded = false,
    this.lowerBoxExpanded = false,
    this.ongoingJourneyPolylines = const [],
    this.ongoingJourneyTransitLineColorCache = const {},
    this.ongoingJourneyCurrentLegIndex,
    this.showLightRail = true,
    this.showStationLabelsLightRail = true,
    this.lightRailLines = const [],
    this.showSubway = true,
    this.showStationLabelsSubway = true,
    this.subwayLines = const [],
    this.showTram = false,
    this.showStationLabelsTram = false,
    this.tramLines = const [],
    this.showFerry = false,
    this.showStationLabelsFerry = true,
    this.ferryLines = const [],
    this.showFunicular = false,
    this.showStationLabelsFunicular = false,
    this.funicularLines = const [],
    this.alignPositionOnUpdate = AlignOnUpdate.always,
    this.faves = const [],
    this.ongoingJourneyOnMap = false,
  }) : currentCenter = currentCenter ?? const LatLng(52.513416, 13.412364);

  HomePageUIState copyWith({
    List<Location>? searchResults,
    String? lastSearchedText,
    LatLng? currentUserLocation,
    LatLng? currentCenter,
    double? currentZoom,
    List<Polyline>? lines,
    List<Station>? stations,
    Savedjourney? ongoingJourney,
    bool clearOngoingJourney = false,
    List<Trip>? tripsForOngoingJourneyLegs,
    List<int>? legsOfOngoingJourneyThatHaveATrip,
    Map<int, Trip>? legIndexToTripMap,
    bool? ongoingJourneyIntermediateStopsExpanded,
    bool? lowerBoxExpanded,
    List<Polyline>? ongoingJourneyPolylines,
    Map<String, Color>? ongoingJourneyTransitLineColorCache,
    int? ongoingJourneyCurrentLegIndex,
    bool clearOngoingJourneyCurrentLegIndex = false,
    bool? showLightRail,
    bool? showStationLabelsLightRail,
    List<Polyline>? lightRailLines,
    bool? showSubway,
    bool? showStationLabelsSubway,
    List<Polyline>? subwayLines,
    bool? showTram,
    bool? showStationLabelsTram,
    List<Polyline>? tramLines,
    bool? showFerry,
    bool? showStationLabelsFerry,
    List<Polyline>? ferryLines,
    bool? showFunicular,
    bool? showStationLabelsFunicular,
    List<Polyline>? funicularLines,
    AlignOnUpdate? alignPositionOnUpdate,
    List<FavoriteLocation>? faves,
    bool? ongoingJourneyOnMap,
  }) {
    return HomePageUIState(
      searchResults: searchResults ?? this.searchResults,
      lastSearchedText: lastSearchedText ?? this.lastSearchedText,
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      currentCenter: currentCenter ?? this.currentCenter,
      currentZoom: currentZoom ?? this.currentZoom,
      lines: lines ?? this.lines,
      stations: stations ?? this.stations,
      ongoingJourney: clearOngoingJourney ? null : (ongoingJourney ?? this.ongoingJourney),
      tripsForOngoingJourneyLegs: tripsForOngoingJourneyLegs ?? this.tripsForOngoingJourneyLegs,
      legsOfOngoingJourneyThatHaveATrip: legsOfOngoingJourneyThatHaveATrip ?? this.legsOfOngoingJourneyThatHaveATrip,
      legIndexToTripMap: legIndexToTripMap ?? this.legIndexToTripMap,
      ongoingJourneyIntermediateStopsExpanded: ongoingJourneyIntermediateStopsExpanded ?? this.ongoingJourneyIntermediateStopsExpanded,
      lowerBoxExpanded: lowerBoxExpanded ?? this.lowerBoxExpanded,
      ongoingJourneyPolylines: ongoingJourneyPolylines ?? this.ongoingJourneyPolylines,
      ongoingJourneyTransitLineColorCache: ongoingJourneyTransitLineColorCache ?? this.ongoingJourneyTransitLineColorCache,
      ongoingJourneyCurrentLegIndex: clearOngoingJourneyCurrentLegIndex ? null : (ongoingJourneyCurrentLegIndex ?? this.ongoingJourneyCurrentLegIndex),
      showLightRail: showLightRail ?? this.showLightRail,
      showStationLabelsLightRail: showStationLabelsLightRail ?? this.showStationLabelsLightRail,
      lightRailLines: lightRailLines ?? this.lightRailLines,
      showSubway: showSubway ?? this.showSubway,
      showStationLabelsSubway: showStationLabelsSubway ?? this.showStationLabelsSubway,
      subwayLines: subwayLines ?? this.subwayLines,
      showTram: showTram ?? this.showTram,
      showStationLabelsTram: showStationLabelsTram ?? this.showStationLabelsTram,
      tramLines: tramLines ?? this.tramLines,
      showFerry: showFerry ?? this.showFerry,
      showStationLabelsFerry: showStationLabelsFerry ?? this.showStationLabelsFerry,
      ferryLines: ferryLines ?? this.ferryLines,
      showFunicular: showFunicular ?? this.showFunicular,
      showStationLabelsFunicular: showStationLabelsFunicular ?? this.showStationLabelsFunicular,
      funicularLines: funicularLines ?? this.funicularLines,
      alignPositionOnUpdate: alignPositionOnUpdate ?? this.alignPositionOnUpdate,
      faves: faves ?? this.faves,
      ongoingJourneyOnMap: ongoingJourneyOnMap ?? this.ongoingJourneyOnMap,
    );
  }
}