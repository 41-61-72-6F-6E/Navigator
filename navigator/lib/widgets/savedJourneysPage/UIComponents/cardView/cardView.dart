import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/cardView/cardViewAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class cardView extends StatelessWidget {
  final int design;
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final Journey journey;
  final bool isFirst;

  const cardView({
    super.key,
    required this.design,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journey,
    required this.isFirst
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return cardViewAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey, isFirst: isFirst);
      // Future designs can be added here
      default:
        return cardViewAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey, isFirst: isFirst);
    }
  }
}