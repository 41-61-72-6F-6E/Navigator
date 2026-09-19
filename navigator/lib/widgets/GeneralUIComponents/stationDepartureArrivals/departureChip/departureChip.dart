import 'package:flutter/material.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/departureChip/departureChipAndroid.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationDepartureArrivalsAndroid.dart';
class DepartureChip extends StatelessWidget {
  final int design;
  final DateTime? origTime;
  final DateTime newTime;
  final String? origPlatform;
  final String? newPlatform;


  const DepartureChip({
    super.key,
    required this.design,
    required this.newTime,
    this.origTime,
    this.origPlatform,
    this.newPlatform,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return DepartureChipAndroid(newTime: newTime, origTime: origTime, newPlatform: newPlatform, origPlatform: origPlatform,);
      default:
        return DepartureChipAndroid(newTime: newTime, origTime: origTime, newPlatform: newPlatform, origPlatform: origPlatform);
    }
  }
}