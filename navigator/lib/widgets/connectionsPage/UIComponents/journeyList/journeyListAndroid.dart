import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/GeneralUIComponents/loadingCircle/loadingCircle.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/journeyCard/journeyCard.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class JourneyListAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final ScrollController? scrollController;
  final bool shouldAutoScrollToTop;
  final VoidCallback onAddEarlier;
  final VoidCallback onAddLater;
  final VoidCallback onResetToNow;
  final void Function(Journey) onJourneyTap;

  const JourneyListAndroid({
    super.key,
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
    if (model.currentJourneys == null) {
      return Expanded(child: Center(child: LoadingCircle(design: 0)));
    }
    if (model.currentJourneys!.isEmpty) {
      return Expanded(child: Center(child: Text('No journeys found')));
    }

    if (shouldAutoScrollToTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController?.hasClients == true) {
          scrollController!.animateTo(
            48,
            duration: Duration(milliseconds: 700),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Expanded(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onResetToNow,
                  child: Text('Now'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAddEarlier,
                    child: Text('Earlier'),
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => JourneyCard(
                design: 0,
                model: model,
                journey: model.currentJourneys![i],
                onJourneyTap: onJourneyTap,
              ),
              childCount: model.currentJourneys!.length,
            ),
          ),
          SliverToBoxAdapter(
            child: OutlinedButton(
              onPressed: onAddLater,
              child: Text('Later'),
            ),
          ),
        ],
      ),
    );
  }
}