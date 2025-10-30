import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';

class SavedJourneyPageUIUtils 
{
  static String generateJourneyTimeText(
    Journey journey,
    bool onlyDate,
    bool onlyTime,
  ) {
    DateTime currentTime = DateTime.now();
    DateTime departureTime = journey.plannedDepartureTime.toLocal();
    DateTime arrivalTime = journey.plannedArrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');

    if (onlyTime) {
      return '$departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }

    if (arrivalTime.isBefore(DateTime.now())) {
      if (onlyDate) {
        return '${departureTime.day}.${departureTime.month}.${departureTime.year}';
      }
      return '${departureTime.day}.${departureTime.month}.${departureTime.year} $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }

    if (departureTime.difference(currentTime).inDays < 3) {
      if (departureTime.day == currentTime.day) {
        if (onlyDate) {
          return 'Today';
        }
        return 'Today $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      } else if (departureTime.day == currentTime.day + 1) {
        if (onlyDate) {
          return 'Tomorrow';
        }
        return 'Tomorrow $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      }
    }

    if (departureTime.subtract(const Duration(days: 7)).isBefore(currentTime)) {
      String weekdayName = '';
      switch (departureTime.weekday) {
        case 1:
          weekdayName = 'Monday';
          break;
        case 2:
          weekdayName = 'Tuesday';
          break;
        case 3:
          weekdayName = 'Wednesday';
          break;
        case 4:
          weekdayName = 'Thursday';
          break;
        case 5:
          weekdayName = 'Friday';
          break;
        case 6:
          weekdayName = 'Saturday';
          break;
        case 7:
          weekdayName = 'Sunday';
          break;
      }
      if (onlyDate) {
        return 'next $weekdayName';
      }
      return 'next $weekdayName $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    } else {
      if (onlyDate) {
        return '${departureTime.day}.${departureTime.month}.${departureTime.year}';
      }
      return '${departureTime.day}.${departureTime.month}.${departureTime.year} $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }
  }

  static String generateLiveTimeText(
    Journey journey,
    bool onlyDeparture,
    bool onlyArrival,
  ) {
    DateTime departureTime = journey.departureTime.toLocal();
    DateTime arrivalTime = journey.arrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');

    if (onlyDeparture) {
      return '$departureHour:$departureMinute';
    }
    if (onlyArrival) {
      return '$arrivalHour:$arrivalMinute';
    }
    return '$departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
  }

  static Widget buildModes(BuildContext context, Journey journey, Color color) {
    List<String> products = [];
    for (Leg leg in journey.legs) {
      if (leg.product != null && leg.product!.isNotEmpty) {
        products.add(leg.product!);
      }
    }

    List<Widget> modeWidgets = [];
    for (int index = 0; index < products.length; index++) {
      if (index > 0) {
        modeWidgets.add(Icon(Icons.chevron_right, color: color, size: 20));
      }
      modeWidgets.add(Icon(
        getModeIcon(products[index]).icon,
        color: color,
        size: 20,
      ));
    }

    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modeWidgets,
      ),
    );
  }

  static Icon getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'bus':
        return const Icon(Icons.directions_bus);
      case 'nationalexpress':
        return const Icon(Icons.train);
      case 'national':
        return const Icon(Icons.train);
      case 'regional':
        return const Icon(Icons.directions_railway);
      case 'regionalexpress':
        return const Icon(Icons.directions_railway);
      case 'suburban':
        return const Icon(Icons.directions_subway);
      case 'subway':
        return const Icon(Icons.subway_outlined);
      case 'tram':
        return const Icon(Icons.tram);
      case 'taxi':
        return const Icon(Icons.local_taxi);
      case 'ferry':
        return const Icon(Icons.directions_boat);
      default:
        return const Icon(Icons.train);
    }
  }

}