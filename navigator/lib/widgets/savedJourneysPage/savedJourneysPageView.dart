import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUp.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/cardView/cardView.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/nextJourney/nextJourney.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/searchBar/searchBar.dart' as mysearchbar;
import 'package:navigator/widgets/savedJourneysPage/UIComponents/savedJourneyPageUIUtils.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/listView/listView.dart' as mylistview;

/// View class for the Saved Journeys page
/// Handles all UI rendering and user interactions
class SavedJourneysPageView extends StatefulWidget {
  final SavedJourneysPageModel model;
  final int design;

  const SavedJourneysPageView({
    super.key,
    required this.model,
    required this.design,
  });

  @override
  State<SavedJourneysPageView> createState() => _SavedJourneysPageViewState();
}

class _SavedJourneysPageViewState extends State<SavedJourneysPageView> {
  late Color successColor;
  late Color onSuccessColor;
  late Color successIconColor;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
    widget.model.loadSavedJourneys();
//    _updateColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateColors();
  }

  void _updateColors() {
    Brightness brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      successColor = const Color(0xFF1C2717);
      onSuccessColor = const Color.fromARGB(255, 195, 230, 183);
      successIconColor = const Color.fromARGB(255, 91, 128, 77);
    } else {
      successColor = const Color.fromARGB(255, 195, 230, 183);
      onSuccessColor = const Color(0xFF1C2717);
      successIconColor = const Color.fromARGB(255, 91, 128, 77);
    }
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {
        widget.model.updateExpandedList();
      });
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSavedJourneysPage(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedJourneysPage(BuildContext context) {
    final state = widget.model.state;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        mysearchbar.SearchBar(design: widget.design, state: state, model: widget.model),       
        if (state.nextJourney != null && !state.showingPastJourneys)
          nextJourney(design: widget.design, state: state, model: widget.model, successColor: successColor, onSuccessColor: onSuccessColor,),
        if (state.showingPastJourneys && state.pastJourneys.isNotEmpty)
          Center(
            child: Text(
              'Past Journeys',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        if (state.showingPastJourneys)
          Expanded(child: _buildJourneysList(context, state.pastJourneys)),
        if (!state.showingPastJourneys)
          Expanded(child: _buildJourneysList(context, state.futureJourneys)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildJourneysList(BuildContext context, List<Savedjourney> journeysList) {
    final state = widget.model.state;
    
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

        return _buildJourneyGroup(context, journeyGroup, index, isExpanded);
      },
    );
  }

  Widget _buildJourneyGroup(
    BuildContext context,
    List<Journey> journeyGroup,
    int index,
    bool isExpanded,
  ) {
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
          _buildGroupHeader(context, journeyGroup, index, isExpanded),
          _buildGroupBody(context, journeyGroup, isExpanded),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    List<Journey> journeyGroup,
    int index,
    bool isExpanded,
  ) {
    return GestureDetector(
      onTap: () => widget.model.toggleExpanded(index),
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

  Widget _buildGroupBody(
    BuildContext context,
    List<Journey> journeyGroup,
    bool isExpanded,
  ) {
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
                      child: _buildJourneyItem(context, journey, isLast),
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildJourneyItem(BuildContext context, Journey journey, bool isLast) {
    final state = widget.model.state;
    
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
              onTap: () => RefreshJourneyPopUp.navigateToJourney(context, journey, widget.model, (model) async {
                await widget.model.loadSavedJourneys();
                widget.model.refreshJourneys(onlyFutureJourneys: !state.showingPastJourneys);
              }),
              child: state.cardView
                  ? cardView(design: widget.design, state: state, model: widget.model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey, isFirst: false)
                  : mylistview.ListView(design: widget.design, state: state, model: widget.model, successColor: successColor, onSuccessColor: onSuccessColor, journey: journey),
            ),
          ),
        ),
      ],
    );
  }

}