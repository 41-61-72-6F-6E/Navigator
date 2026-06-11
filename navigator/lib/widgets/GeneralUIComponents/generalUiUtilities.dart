import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/line.dart';

class GeneralUIUtilities {
  Icon getIconFromLine(Line line) {
    Icon icon;
    switch (line.product) {
      case 'bus':
        icon = Icon(Icons.directions_bus);
        break;
      case 'nationalExpress':
        icon = Icon(Icons.train);
        break;
      case 'national':
        icon = Icon(Icons.train);
        break;
      case 'regional':
        icon = Icon(Icons.directions_railway);
        break;
      case 'regionalExpress':
        icon = Icon(Icons.directions_railway);
        break;
      case 'suburban':
        icon = Icon(Icons.directions_subway);
        break;
      case 'subway':
        icon = Icon(Icons.subway_outlined);
        break;
      case 'tram':
        icon = Icon(Icons.tram);
        break;
      case 'taxi':
        icon = Icon(Icons.local_taxi);
        break;
      case 'ferry':
        icon = Icon(Icons.directions_boat);
        break;
      default:
        icon = Icon(Icons.directions_walk);
    }
    return icon;
  }

  String getTextfromDateTime(DateTime data)
  {
    DateTime time = data.toLocal();
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
