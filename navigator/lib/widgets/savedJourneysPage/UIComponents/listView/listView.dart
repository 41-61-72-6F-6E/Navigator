import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/listView/listViewAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class ListView extends StatelessWidget {
  final int design;
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final Journey journey;

  const ListView({
    super.key,
    required this.design,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return ListViewAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey);
      // Future designs can be added here
      default:
        return ListViewAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey);
    }
  }
}