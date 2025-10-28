import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
/// View class for the Saved Journeys page
/// Handles all UI rendering and user interactions
class SavedJourneysPageView extends StatefulWidget {
  final SavedJourneysPageModel model;

  const SavedJourneysPageView({
    super.key,
    required this.model,
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
        _buildSearchBar(context),
        if (state.nextJourney != null && !state.showingPastJourneys)
          _buildNextJourney(context),
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

  Widget _buildSearchBar(BuildContext context) {
    final state = widget.model.state;
    
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          elevation: WidgetStateProperty.all(0),
          controller: controller,
          hintText: 'Search saved journeys',
          trailing: <Widget>[
            Tooltip(
              message: "Filter your search",
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Implement filter functionality here
                },
              ),
            ),
            if (state.cardView)
              Tooltip(
                message: "Switch to list view",
                child: IconButton(
                  onPressed: () => widget.model.toggleViewMode(),
                  icon: const Icon(Icons.list),
                ),
              ),
            if (!state.cardView)
              Tooltip(
                message: "Switch to card view",
                child: IconButton(
                  onPressed: () => widget.model.toggleViewMode(),
                  icon: const Icon(Icons.view_agenda_outlined),
                ),
              ),
            MenuAnchor(
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return Tooltip(
                  message: 'More Options',
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      controller.open();
                    },
                  ),
                );
              },
              menuChildren: [
                MenuItemButton(
                  onPressed: () => widget.model.togglePastJourneysView(),
                  child: Text(
                    state.showingPastJourneys
                        ? 'Show Future Journeys'
                        : 'Show Past Journeys',
                  ),
                ),
                MenuItemButton(
                  onPressed: () {},
                  child: const Text('Settings'),
                ),
              ],
            ),
          ],
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return List<ListTile>.generate(5, (int index) {
          final String item = 'item $index';
          return ListTile(
            title: Text(item),
            onTap: () {
              setState(() {
                controller.closeView(item);
              });
            },
          );
        });
      },
    );
  }

  Widget _buildNextJourney(BuildContext context) {
    final state = widget.model.state;
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
      onTap: () => _navigateToJourney(context, nextJourney.journey),
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
                      _generateJourneyTimeText(nextJourney.journey, true, false),
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
                  child: _buildCardView(context, nextJourney.journey, true),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  _generateJourneyTimeText(journeyGroup.first, true, false),
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
              onTap: () => _navigateToJourney(context, journey),
              child: state.cardView
                  ? _buildCardView(context, journey, false)
                  : _buildListView(context, journey),
            ),
          ),
        ),
      ],
    );
  }

  // Navigation helper method
  Future<void> _navigateToJourney(BuildContext context, Journey journey) async {
    final outerContext = context;

    showDialog(
      context: outerContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Refreshing journey information...',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final refreshedJourney =
          await widget.model.refreshSingleJourney(journey.refreshToken);

      if (outerContext.mounted) {
        Navigator.of(outerContext, rootNavigator: true).pop();
      }

      if (outerContext.mounted) {
        Navigator.of(outerContext, rootNavigator: false)
            .push(
          MaterialPageRoute(
            builder: (context) => JourneyPageAndroid(
              JourneyPage(journey: refreshedJourney),
              journey: refreshedJourney,
            ),
          ),
        )
            .then((_) {
          widget.model.loadSavedJourneys().then((_) {
            widget.model.refreshJourneys(onlyFutureJourneys: true);
          });
        });
      }
    } catch (e) {
      if (outerContext.mounted) {
        Navigator.of(outerContext, rootNavigator: true).pop();
      }

      if (outerContext.mounted) {
        ScaffoldMessenger.of(outerContext).showSnackBar(
          SnackBar(
            content: Text('Could not refresh journey: ${e.toString()}'),
            backgroundColor: Theme.of(outerContext).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildCardView(BuildContext context, Journey journey, bool isFirst) {
    bool delayed = false;
    String timeText = _generateJourneyTimeText(journey, false, true);
    Text liveTimeTextP1 = const Text('');
    Text liveTimeTextP2 = const Text('');

    Color yLight = const Color.fromARGB(255, 229, 241, 116);
    Color yDark = const Color.fromARGB(255, 166, 175, 34);
    Color y = yLight;
    Color g = onSuccessColor;

    if (Theme.of(context).brightness == Brightness.dark) {
      y = isFirst ? yDark : yLight;
    } else {
      y = isFirst ? yLight : yDark;
    }

    if (isFirst) {
      g = successColor;
    }

    if (journey.legs.first.departureDelayMinutes != null) {
      delayed = true;
      Color c = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
      c = journey.legs.first.departureDelayMinutes! >= 15
          ? Theme.of(context).colorScheme.error
          : c;
      liveTimeTextP1 = Text(
        _generateLiveTimeText(journey, true, false),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
      );
    }

    if (journey.legs.last.arrivalDelayMinutes != null) {
      if (delayed) {
        Color cD = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
        cD = journey.legs.first.departureDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cD;
        Color cA = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        cA = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cA;
        liveTimeTextP1 = Text(
          _generateLiveTimeText(journey, true, false),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cD),
        );
        liveTimeTextP2 = Text(
          _generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cA),
        );
      } else {
        delayed = true;
        Color c = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        c = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : c;
        liveTimeTextP2 = Text(
          _generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
        );
        liveTimeTextP1 = Text(
          '          ',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
    }

    return Padding(
      padding: isFirst
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isFirst ? 16 : 16.0,
          horizontal: 16,
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trip_origin,
                          color: isFirst
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            journey.legs.first.origin.name,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: isFirst
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    SvgPicture.asset(
                      "assets/Icon/go_to_line.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isFirst
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                        BlendMode.srcIn,
                      ),
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/Icon/distance.svg",
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            isFirst
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            journey.legs.last.destination.name,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: isFirst
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: isFirst
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  timeText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: isFirst
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (delayed)
                                Row(
                                  children: [
                                    liveTimeTextP1,
                                    Text(
                                      ' - ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: isFirst
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    liveTimeTextP2,
                                  ],
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        _buildModes(
                          context,
                          journey,
                          isFirst
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.errorContainer,
                          ),
                          onPressed: () {},
                          label: Text(
                            'no Ticket',
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: SvgPicture.asset(
                            "assets/Icon/transit_ticket.svg",
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onErrorContainer,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, Journey journey) {
    bool delayed = false;
    String timeText = _generateJourneyTimeText(journey, false, true);
    Text liveTimeTextP1 = const Text('');
    Text liveTimeTextP2 = const Text('');
    Icon modeIcon = Icon(
      Icons.train,
      color: Theme.of(context).colorScheme.tertiary,
    );

    String highestMode = _findHighestMode(journey);
    modeIcon = Icon(
      _getModeIcon(highestMode).icon,
      color: Theme.of(context).colorScheme.tertiary,
    );

    if (journey.legs.first.departureDelayMinutes != null ||
        journey.legs.last.arrivalDelayMinutes != null) {
      delayed = true;
    }

    Color y = Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 229, 241, 116)
        : const Color.fromARGB(255, 166, 175, 34);
    Color g = onSuccessColor;

    if (journey.legs.first.departureDelayMinutes != null) {
      delayed = true;
      Color c = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
      c = journey.legs.first.departureDelayMinutes! >= 15
          ? Theme.of(context).colorScheme.error
          : c;
      liveTimeTextP1 = Text(
        _generateLiveTimeText(journey, true, false),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
      );
    }

    if (journey.legs.last.arrivalDelayMinutes != null) {
      if (delayed) {
        Color cD = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
        cD = journey.legs.first.departureDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cD;
        Color cA = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        cA = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cA;
        liveTimeTextP1 = Text(
          _generateLiveTimeText(journey, true, false),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cD),
        );
        liveTimeTextP2 = Text(
          _generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cA),
        );
      } else {
        delayed = true;
        Color c = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        c = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : c;
        liveTimeTextP2 = Text(
          _generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
        );
        liveTimeTextP1 = Text(
          '        ',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: () => _navigateToJourney(context, journey),
          leading: modeIcon,
          title: Text(
            '${journey.legs.first.origin.name} - ${journey.legs.last.destination.name}',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Row(
            children: [
              Text(
                timeText,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              if (delayed) liveTimeTextP1,
              if (delayed)
                Text(
                  ' - ',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              if (delayed) liveTimeTextP2,
            ],
          ),
          trailing: IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              "assets/Icon/transit_ticket.svg",
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onErrorContainer,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModes(BuildContext context, Journey journey, Color color) {
    List<String> products = [];
    for (Leg leg in journey.legs) {
      if (leg.product != null && leg.product!.isNotEmpty) {
        products.add(leg.product!);
      }
    }

    List<Widget> modeWidgets = [];
    for (int index = 0; index < products.length; index++) {
      if (index > 0) {
        modeWidgets.add(Icon(Icons.chevron_right, color: color, size: 20));
      }
      modeWidgets.add(Icon(
        _getModeIcon(products[index]).icon,
        color: color,
        size: 20,
      ));
    }

    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modeWidgets,
      ),
    );
  }

  Icon _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'bus':
        return const Icon(Icons.directions_bus);
      case 'nationalexpress':
        return const Icon(Icons.train);
      case 'national':
        return const Icon(Icons.train);
      case 'regional':
        return const Icon(Icons.directions_railway);
      case 'regionalexpress':
        return const Icon(Icons.directions_railway);
      case 'suburban':
        return const Icon(Icons.directions_subway);
      case 'subway':
        return const Icon(Icons.subway_outlined);
      case 'tram':
        return const Icon(Icons.tram);
      case 'taxi':
        return const Icon(Icons.local_taxi);
      case 'ferry':
        return const Icon(Icons.directions_boat);
      default:
        return const Icon(Icons.train);
    }
  }

  String _findHighestMode(Journey journey) {
    String currentHighest = 'walk';
    for (Leg l in journey.legs) {
      if (l.product != null && l.product!.isNotEmpty) {
        if (_modeIsHigher(currentHighest, l.product!)) {
          currentHighest = l.product!;
        }
      }
    }
    return currentHighest;
  }

  bool _modeIsHigher(String compareMode, String newMode) {
    List<String> modes = [
      'walk',
      'taxi',
      'bus',
      'tram',
      'ferry',
      'subway',
      'suburban',
      'regional',
      'regionalexpress',
      'national',
      'nationalexpress'
    ];
    int compareIndex = modes.indexOf(compareMode.toLowerCase());
    int newIndex = modes.indexOf(newMode.toLowerCase());
    return newIndex > compareIndex;
  }

  String _generateLiveTimeText(
    Journey journey,
    bool onlyDeparture,
    bool onlyArrival,
  ) {
    DateTime departureTime = journey.departureTime.toLocal();
    DateTime arrivalTime = journey.arrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');

    if (onlyDeparture) {
      return '$departureHour:$departureMinute';
    }
    if (onlyArrival) {
      return '$arrivalHour:$arrivalMinute';
    }
    return '$departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
  }

  String _generateJourneyTimeText(
    Journey journey,
    bool onlyDate,
    bool onlyTime,
  ) {
    DateTime currentTime = DateTime.now();
    DateTime departureTime = journey.plannedDepartureTime.toLocal();
    DateTime arrivalTime = journey.plannedArrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');

    if (onlyTime) {
      return '$departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }

    if (arrivalTime.isBefore(DateTime.now())) {
      if (onlyDate) {
        return '${departureTime.day}.${departureTime.month}.${departureTime.year}';
      }
      return '${departureTime.day}.${departureTime.month}.${departureTime.year} $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }

    if (departureTime.difference(currentTime).inDays < 3) {
      if (departureTime.day == currentTime.day) {
        if (onlyDate) {
          return 'Today';
        }
        return 'Today $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      } else if (departureTime.day == currentTime.day + 1) {
        if (onlyDate) {
          return 'Tomorrow';
        }
        return 'Tomorrow $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      }
    }

    if (departureTime.subtract(const Duration(days: 7)).isBefore(currentTime)) {
      String weekdayName = '';
      switch (departureTime.weekday) {
        case 1:
          weekdayName = 'Monday';
          break;
        case 2:
          weekdayName = 'Tuesday';
          break;
        case 3:
          weekdayName = 'Wednesday';
          break;
        case 4:
          weekdayName = 'Thursday';
          break;
        case 5:
          weekdayName = 'Friday';
          break;
        case 6:
          weekdayName = 'Saturday';
          break;
        case 7:
          weekdayName = 'Sunday';
          break;
      }
      if (onlyDate) {
        return 'next $weekdayName';
      }
      return 'next $weekdayName $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    } else {
      if (onlyDate) {
        return '${departureTime.day}.${departureTime.month}.${departureTime.year}';
      }
      return '${departureTime.day}.${departureTime.month}.${departureTime.year} $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }
  }
}