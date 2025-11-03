import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/journeysList/journeyGroup.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class journeysListWidget extends StatelessWidget {
  final int design;
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final List<Savedjourney> journeysList;

  const journeysListWidget({
    super.key,
    required this.design,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journeysList
  });

  @override
  Widget build(BuildContext context) {
    
    if (journeysList.isEmpty) {
      return Center(
        child: state.showingPastJourneys
            ? Text(
                'No past journeys',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                'No saved journeys',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      );
    }

    List<Savedjourney> journeys = List.from(journeysList);
    if (!state.showingPastJourneys && journeys.isNotEmpty) {
      journeys.removeAt(0);
    }

    if (journeys.isEmpty && !state.showingPastJourneys) {
      return Center(
        child: Text(
          'No more saved journeys',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
    }

    List<List<Journey>> journeysByDate = state.journeysByDate
        .map((list) => list.map((sj) => sj.journey).toList())
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: journeysByDate.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        List<Journey> journeyGroup = journeysByDate[index];
        bool isExpanded = index < state.isExpandedList.length
            ? state.isExpandedList[index]
            : false;

        return JourneyGroup(design: design, state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journeyGroup: journeyGroup, isExpanded: isExpanded, index: index);
      },
    );
  }
}