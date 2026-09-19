import 'package:flutter/material.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationDepartureArrivalsAndroid.dart';
class StationDepartureArrivals extends StatelessWidget {
  final int design;
  final ValueChanged<String> onTripSelected; // This takes a trip id
  final List<DepartureArrival> data;
  final bool isLoading;

  const StationDepartureArrivals({
    super.key,
    required this.design,
    required this.onTripSelected,
    required this.data,
    required this.isLoading
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return StationDepartureArrivalsAndroid(onTripSelected: onTripSelected, data: data,isLoading: isLoading,);
      default:
        return StationDepartureArrivalsAndroid(onTripSelected: onTripSelected, data: data,isLoading: isLoading,);
    }
  }
}