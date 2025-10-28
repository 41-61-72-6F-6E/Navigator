import 'package:navigator/models/journey.dart';

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
}