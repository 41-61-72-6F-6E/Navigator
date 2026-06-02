import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/journeyList/journeyListAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class JourneyList extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final ScrollController? scrollController;
  final bool shouldAutoScrollToTop;
  final VoidCallback onAddEarlier;
  final VoidCallback onAddLater;
  final VoidCallback onResetToNow;
  final void Function(Journey) onJourneyTap;

  const JourneyList({
    super.key,
    required this.design,
    required this.model,
    required this.scrollController,
    required this.shouldAutoScrollToTop,
    required this.onAddEarlier,
    required this.onAddLater,
    required this.onResetToNow,
    required this.onJourneyTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return JourneyListAndroid(
          model: model,
          scrollController: scrollController,
          shouldAutoScrollToTop: shouldAutoScrollToTop,
          onAddEarlier: onAddEarlier,
          onAddLater: onAddLater,
          onResetToNow: onResetToNow,
          onJourneyTap: onJourneyTap,
        );
      default:
        return JourneyListAndroid(
          model: model,
          scrollController: scrollController,
          shouldAutoScrollToTop: shouldAutoScrollToTop,
          onAddEarlier: onAddEarlier,
          onAddLater: onAddLater,
          onResetToNow: onResetToNow,
          onJourneyTap: onJourneyTap,
        );
    }
  }
}