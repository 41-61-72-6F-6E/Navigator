import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/journeysList/groupBody/groupBodyAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/journeysList/groupHeader/groupHeaderAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class JourneyGroup extends StatelessWidget {
  final int design;
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final List<Journey> journeyGroup;
  final bool isExpanded;
  final int index;

  const JourneyGroup({
    super.key,
    required this.design,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journeyGroup,
    required this.isExpanded,
    required this.index
  });

  @override
  Widget build(BuildContext context) {
    Widget groupHeader;
    Widget groupBody;
    switch(design)
    {
      case 0:
        groupHeader = GroupHeaderAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journeyGroup: journeyGroup, isExpanded: isExpanded, index: index);
        groupBody = GroupBodyAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journeyGroup: journeyGroup, isExpanded: isExpanded);
        break;
      // Future designs can be added here
      default:
        groupHeader = GroupHeaderAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journeyGroup: journeyGroup, isExpanded: isExpanded, index: index);
        groupBody = GroupBodyAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, journeyGroup: journeyGroup, isExpanded: isExpanded);
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        children: [
          groupHeader,
          groupBody,
        ],
      ),
    );
  }
}