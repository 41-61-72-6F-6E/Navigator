import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/journeysList/journeyItem/journeyItemAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class GroupBodyAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final List<Journey> journeyGroup;
  final bool isExpanded;

  const GroupBodyAndroid({
    super.key,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journeyGroup,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isExpanded ? null : 0,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: isExpanded ? 400 : 200),
          opacity: isExpanded ? 1.0 : 0.0,
          curve: isExpanded ? Curves.easeIn : Curves.easeOut,
          child: isExpanded
              ? Column(
                  children: journeyGroup.asMap().entries.map<Widget>((entry) {
                    int idx = entry.key;
                    Journey journey = entry.value;
                    bool isLast = idx == journeyGroup.length - 1;

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (idx * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: clampDouble(value, 0, 1),
                            child: child,
                          ),
                        );
                      },
                      child: JourneyItemAndroid(state: state, model: model, successColor: successColor, onSuccessColor: onSuccessColor, isExpanded: isExpanded, isLast: isLast, journey: journey),
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}