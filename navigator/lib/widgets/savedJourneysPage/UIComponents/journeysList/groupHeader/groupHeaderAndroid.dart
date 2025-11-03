import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/savedJourneyPageUIUtils.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class GroupHeaderAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final List<Journey> journeyGroup;
  final bool isExpanded;
  final int index;

  const GroupHeaderAndroid({
    super.key,
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
    
    return GestureDetector(
      onTap: () => model.toggleExpanded(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: isExpanded
              ? const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                )
              : BorderRadius.circular(24.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: isExpanded
                      ? Theme.of(context).colorScheme.onTertiaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                child: Text(
                  SavedJourneyPageUIUtils.generateJourneyTimeText(journeyGroup.first, true, false),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isExpanded
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4.0),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: isExpanded
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: Text('${journeyGroup.length}'),
                  ),
                  const SizedBox(width: 4.0),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isExpanded
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}