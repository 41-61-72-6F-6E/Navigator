import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/models/station.dart';

class StationSheetNotifier extends ChangeNotifier {
  List<DepartureArrival> loadedDepartureArrivals;
  List<DepartureArrival> loadedDepartures;
  List<DepartureArrival> loadedArrivals;
  Station? selectedStation;

  bool showDepartures;
  bool showArrivals;

  bool loading;

  StationSheetNotifier({
    this.loadedDepartureArrivals = const [],
    this.showDepartures = true,
    this.showArrivals = false,
    this.loadedArrivals = const [],
    this.loadedDepartures = const [],
    this.loading = true
  });


  void selectStation(Station station)
  {
    selectedStation = station;
    notifyListeners();
  }

  void deselectStation()
  {
    selectedStation = null;
    clearDepartures();
    clearArrivals();
    notifyListeners();
  }

  void setShowArrivals(bool value) {
    showArrivals = value;
    showDepartures = !value;
    notifyListeners();
  }
  void setShowDepartures(bool value) {
    showDepartures = value;
    showArrivals = !value;
    notifyListeners();
  }

  bool getShowDepartures()
  {
    return showDepartures;
  }

  bool getShowArrivals()
  {
    return showArrivals;
  }

  void updateDepartures(List<DepartureArrival> list)
  {
    loadedDepartures = list;
    loadedDepartureArrivals = loadedDepartures;
    notifyListeners();
  }

  void clearDepartures()
  {
    loadedDepartureArrivals = [];
    loadedDepartures = [];
    notifyListeners();
  }

  void updateArrivals(List<DepartureArrival> list)
  {
    loadedArrivals = list;
    loadedDepartureArrivals = loadedArrivals;
    notifyListeners();
  }

  void clearArrivals()
  {
    loadedDepartureArrivals = [];
    loadedArrivals = [];
    notifyListeners();
  }

  void clearDeparturesAndArrivals()
  {
    loadedDepartures = [];
    loadedArrivals = [];
    loadedDepartureArrivals = [];
    showDepartures = true;
    showArrivals = false;
  }

  void setLoading(bool value)
  {
    loading = value;
    notifyListeners();
  }

}