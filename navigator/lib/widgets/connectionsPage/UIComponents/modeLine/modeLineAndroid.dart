import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class ModeLineAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final Journey journey;

  const ModeLineAndroid({
    super.key,
    required this.model,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    final Journey j = journey;
    int totalTripDuration = j.legs.last.plannedArrivalDateTime
        .difference(j.legs.first.plannedDepartureDateTime)
        .inSeconds;
    List<String> legNames = [];
    List<double> legPercentages = [];
    List<String> legLineNames = [];

    List<int> actualLegIndices = [];

    for (int index = 0; index < j.legs.length; index++) {
      final leg = j.legs[index];
      bool isSameStationInterchange =
          leg.origin.id == leg.destination.id &&
          leg.origin.name == leg.destination.name;
      bool isWalkingWithinStationComplex = leg.isWalking == true &&
          leg.origin.ril100Ids.isNotEmpty &&
          leg.destination.ril100Ids.isNotEmpty &&
          model.haveSameRil100ID(
              leg.origin.ril100Ids, leg.destination.ril100Ids);
      if (!isSameStationInterchange && !isWalkingWithinStationComplex) {
        actualLegIndices.add(index);
      }
    }

    for (int i = 0; i < actualLegIndices.length; i++) {
      int legIndex = actualLegIndices[i];
      Leg l = j.legs[legIndex];

      if ((l.product == null || l.product!.isEmpty) &&
          l.productName == null) {
        int legDuration = l.plannedArrivalDateTime
            .difference(l.plannedDepartureDateTime)
            .inSeconds;
        double percentage = (legDuration / totalTripDuration) * 100;
        if (model.haveSameRil100ID(
            l.origin.ril100Ids, l.destination.ril100Ids)) {
          legNames.add('transfer');
          legLineNames.add('');
        } else {
          legNames.add('walk');
          legLineNames.add('');
        }
        legPercentages.add(percentage);
      } else {
        int legDuration = l.plannedArrivalDateTime
            .difference(l.plannedDepartureDateTime)
            .inSeconds;
        double percentage = (legDuration / totalTripDuration) * 100;
        if (l.product == null && l.productName != null) {
          legNames.add(l.productName!.toLowerCase());
        } else {
          legNames.add(l.product!);
        }
        legLineNames.add(l.lineName!);
        legPercentages.add(percentage);
      }

      if (i < actualLegIndices.length - 1) {
        int nextLegIndex = actualLegIndices[i + 1];
        Leg nextLeg = j.legs[nextLegIndex];

        bool shouldShowTransfer = false;

        if (nextLegIndex - legIndex > 1) {
          for (int interchangeIndex = legIndex + 1;
              interchangeIndex < nextLegIndex;
              interchangeIndex++) {
            final interchangeLeg = j.legs[interchangeIndex];
            if (interchangeLeg.origin.id ==
                    interchangeLeg.destination.id &&
                interchangeLeg.origin.name ==
                    interchangeLeg.destination.name) {
              shouldShowTransfer = true;
              break;
            }
          }
        } else if (l.destination.id == nextLeg.origin.id &&
            l.destination.name == nextLeg.origin.name &&
            ((l.isWalking == true && nextLeg.isWalking != true) ||
                (l.isWalking != true && nextLeg.isWalking == true) ||
                (l.isWalking != true &&
                    nextLeg.isWalking != true &&
                    l.lineName != nextLeg.lineName))) {
          shouldShowTransfer = true;
        }

        bool isWithinStationComplex =
            l.destination.ril100Ids.isNotEmpty &&
            nextLeg.origin.ril100Ids.isNotEmpty &&
            model.haveSameRil100ID(
                l.destination.ril100Ids, nextLeg.origin.ril100Ids);

        if (isWithinStationComplex || shouldShowTransfer) {
          int transferTime = nextLeg.plannedDepartureDateTime
              .difference(l.plannedArrivalDateTime)
              .inSeconds;
          if (transferTime > 0) {
            double transferPercentage =
                (transferTime / totalTripDuration) * 100;
            legNames.add('transfer');
            legLineNames.add('');
            legPercentages.add(transferPercentage);
          }
        }
      }
    }

    for (int i = 0; i < legNames.length; i++) {
      print(legNames[i] + legPercentages[i].toString());
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: List.generate(legNames.length, (index) {
              double segmentWidth =
                  constraints.maxWidth * (legPercentages[index] / 100);
              Icon icon = Icon(Icons.directions_walk);
              bool light =
                  Theme.of(context).brightness == Brightness.light;
              Color color = Colors.grey;
              Color onColor = light ? Colors.white : Colors.black;
              bool showText = true;
              String text = legLineNames[index];

              const double minWidthForIcon = 24.0;
              const double minWidthForText = 60.0;

              bool shouldShowIcon = segmentWidth >= minWidthForIcon;
              bool shouldShowTextContent =
                  segmentWidth >= minWidthForText && showText;

              switch (legNames[index]) {
                case 'transfer':
                  icon = Icon(Icons.transfer_within_a_station);
                  showText = false;
                  break;
                case 'walk':
                  icon = Icon(Icons.directions_walk);
                  showText = false;
                  break;
                case 'bus':
                  icon = Icon(Icons.directions_bus);
                  color = light
                      ? Colors.deepPurple
                      : Colors.purpleAccent;
                  break;
                case 'nationalExpress':
                  icon = Icon(Icons.train);
                  color = light ? Colors.black : Colors.white;
                  break;
                case 'national':
                  icon = Icon(Icons.train);
                  color = light
                      ? Colors.teal.shade900
                      : Colors.teal.shade300;
                  break;
                case 'regional':
                  icon = Icon(Icons.directions_railway);
                  color = light
                      ? Colors.yellow.shade900
                      : Colors.yellow.shade300;
                  break;
                case 'regionalExpress':
                  icon = Icon(Icons.directions_railway);
                  color = light
                      ? Colors.pink.shade900
                      : Colors.pink.shade300;
                  break;
                case 'suburban':
                  icon = Icon(Icons.directions_subway);
                  color = light
                      ? Colors.green.shade900
                      : Colors.green.shade300;
                  break;
                case 'subway':
                  icon = Icon(Icons.subway_outlined);
                  color = light
                      ? Colors.blue.shade900
                      : Colors.blue.shade300;
                  break;
                case 'tram':
                  icon = Icon(Icons.tram);
                  color = light
                      ? Colors.deepOrange.shade900
                      : Colors.deepOrange.shade300;
                  break;
                case 'taxi':
                  icon = Icon(Icons.local_taxi);
                  color = light
                      ? Colors.amber.shade300
                      : Colors.amber.shade700;
                  break;
                case 'ferry':
                  icon = Icon(Icons.directions_boat);
                  color = light
                      ? Colors.cyan.shade300
                      : Colors.cyan.shade800;
                  break;
                default:
                  icon = Icon(Icons.directions_walk);
                  showText = false;
              }

              return Flexible(
                flex: math.max(legPercentages[index].round(), 1),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(color: color),
                  child: shouldShowIcon
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 4),
                            child: shouldShowTextContent
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(icon.icon,
                                          color: onColor, size: 16),
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4.0),
                                          child: Text(
                                            text,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: onColor,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Icon(icon.icon,
                                    color: onColor, size: 16),
                          ),
                        )
                      : Container(),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}