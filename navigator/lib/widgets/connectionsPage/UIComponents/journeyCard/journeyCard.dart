import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/journeyCard/journeyCardAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class JourneyCard extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final Journey journey;
  final void Function(Journey) onJourneyTap;

  const JourneyCard({
    super.key,
    required this.design,
    required this.model,
    required this.journey,
    required this.onJourneyTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return JourneyCardAndroid(
          model: model,
          journey: journey,
          onJourneyTap: onJourneyTap,
        );
      default:
        return JourneyCardAndroid(
          model: model,
          journey: journey,
          onJourneyTap: onJourneyTap,
        );
    }
  }
}