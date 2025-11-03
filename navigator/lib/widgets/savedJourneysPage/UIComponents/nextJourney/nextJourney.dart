import 'package:flutter/material.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/nextJourney/nextJourneyAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class nextJourney extends StatelessWidget {
  final int design;
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;

  const nextJourney({
    super.key,
    required this.design,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return nextJourneyAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor,);
      // Future designs can be added here
      default:
        return nextJourneyAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor,);
    }
  }
}