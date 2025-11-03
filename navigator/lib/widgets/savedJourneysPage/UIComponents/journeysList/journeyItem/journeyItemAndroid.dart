import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUp.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/cardView/cardView.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/listView/listView.dart' as mylistview;

class JourneyItemAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final bool isExpanded;
  final bool isLast;
  final Journey journey;

  const JourneyItemAndroid({
    super.key,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.isExpanded,
    required this.isLast,
    required this.journey
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.surface,
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(24.0),
                    bottomRight: Radius.circular(24.0),
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(24.0),
                      bottomRight: Radius.circular(24.0),
                    )
                  : null,
              onTap: () => RefreshJourneyPopUp.navigateToJourney(context, journey, model, (model) async {
                await model.loadSavedJourneys();
                model.refreshJourneys(onlyFutureJourneys: !state.showingPastJourneys);
              }),
              child: state.cardView
                  ? cardView(design: 0, state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey, isFirst: false)
                  : mylistview.ListView(design: 0, state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey),
            ),
          ),
        ),
      ],
    );
  }
}