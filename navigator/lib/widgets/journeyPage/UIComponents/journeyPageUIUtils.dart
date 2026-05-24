import 'package:intl/intl.dart';
import 'package:navigator/models/leg.dart';

String formatLegDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '0min';
    final duration = end.difference(start);
    final minutes = (duration.inSeconds / 60).ceil();
    return minutes <= 0 ? '1min' : '${minutes}min';
  }

  bool haveSameRil100Station(List<String> ids1, List<String> ids2) {
    if (ids1.isEmpty || ids2.isEmpty) return false;
    for (final id1 in ids1) {
      for (final id2 in ids2) {
        if (id1 == id2) return true;
      }
    }
    return false;
  }

  String? getPlatformChangeText(Leg leg, int index, List<Leg> legs) {
    if (leg.isWalking != true || index <= 0 || index >= legs.length - 1) {
      return null;
    }
    final prevLeg = legs[index - 1];
    final nextLeg = legs[index + 1];
    if (prevLeg.arrivalPlatformEffective.isNotEmpty &&
        nextLeg.departurePlatformEffective.isNotEmpty &&
        prevLeg.arrivalPlatformEffective !=
            nextLeg.departurePlatformEffective) {
      return 'Platform change: ${prevLeg.arrivalPlatformEffective} to ${nextLeg.departurePlatformEffective}';
    }
    return null;
  }

  String formatModifiedDate(String? modifiedStr) {
    if (modifiedStr == null || modifiedStr.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(modifiedStr);
      if (dateTime.isUtc) dateTime = dateTime.toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    } catch (_) {
      return modifiedStr;
    }
  }