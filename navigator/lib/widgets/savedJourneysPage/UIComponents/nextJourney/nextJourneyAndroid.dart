import 'package:flutter/material.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUp.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/savedJourneyPageUIUtils.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageView.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/cardView/cardView.dart';

class nextJourneyAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;

  const nextJourneyAndroid({
    super.key,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
  });

  @override
  Widget build(BuildContext context) {    
    final nextJourney = state.nextJourney;
    
    if (nextJourney == null) return const SizedBox.shrink();

    bool delayed = false;
    String delayText = 'no delays';
    
    if (nextJourney.journey.legs.first.departureDelayMinutes != null) {
      delayed = true;
      delayText = 'Departure delayed';
    }
    if (nextJourney.journey.legs.last.arrivalDelayMinutes != null) {
      delayText = delayed ? 'Delayed' : 'Arrival delayed';
      delayed = true;
    }

    Color delayColor = delayed
        ? Theme.of(context).colorScheme.errorContainer
        : successColor;
    
    Color onDelayColor = delayed
        ? Theme.of(context).colorScheme.onErrorContainer
        : onSuccessColor;

    bool ongoing = state.isNextJourneyOngoing;

    return GestureDetector(
      onTap: () => RefreshJourneyPopUp.navigateToJourney(context, nextJourney.journey, model, (model) async {
                await model.loadSavedJourneys();
                model.refreshJourneys(onlyFutureJourneys: model.state.showingPastJourneys);
              }),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Text(
                      ongoing ? 'Ongoing Journey' : 'Next Journey',
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      SavedJourneyPageUIUtils.generateJourneyTimeText(nextJourney.journey, true, false),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(24),
                elevation: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: cardView(design: 0, state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journey: nextJourney.journey, isFirst: true,),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}