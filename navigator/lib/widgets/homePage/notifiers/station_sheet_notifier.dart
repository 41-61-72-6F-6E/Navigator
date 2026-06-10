import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/models/station.dart';

class StationSheetNotifier extends ChangeNotifier {
  List<DepartureArrival> loadedDepartureArrivals;
  Station? selectedStation;

  bool showDepartures;
  bool showArrivals;

  StationSheetNotifier({
    this.loadedDepartureArrivals = const [],
    this.showDepartures = true,
    this.showArrivals = false,
  });


  void selectStation(Station station)
  {
    selectedStation = station;
    notifyListeners();
  }

  void deselectStation()
  {
    selectedStation = null;
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

  void updateDepartureArrivals(List<DepartureArrival> list)
  {
    loadedDepartureArrivals = list;
    notifyListeners();
  }

}