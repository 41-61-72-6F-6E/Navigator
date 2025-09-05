import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/localDataSaver.dart';

class SavedjourneysPageAndroid extends StatefulWidget {
  final SavedjourneysPage page;
  List<String> savedJourneyrefreshTokens = [];

  SavedjourneysPageAndroid(this.page, this.savedJourneyrefreshTokens, {Key? key}) : super(key: key);

  @override
  State<SavedjourneysPageAndroid> createState() =>
      _SavedjourneysPageAndroidState();
}

class _SavedjourneysPageAndroidState extends State<SavedjourneysPageAndroid> {
  List<String> savedJourneyrefreshTokens = [];
  List<Journey> savedJourneys = [];
  List<Journey> pastJourneys = [];
  List<Journey> futureJourneys = [];
  List<bool> isExpandedList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  bool showingPastJourneys = false;
  bool cardView = true;
  Color successColor = Color.fromARGB(255, 195, 230, 183);
  Color onSuccessColor = Color.fromARGB(255, 50, 70, 42);
  Color successIconColor = Color.fromARGB(255, 91, 128, 77);


  @override
void didUpdateWidget(SavedjourneysPageAndroid oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Force reload when widget updates
  WidgetsBinding.instance.addPostFrameCallback((_) {
    getSavedJourneyRefreshTokens();
    Brightness brightness = Theme.of(context).brightness;
    if(brightness == Brightness.dark)
    {
      successColor = Color(0xFF1C2717);
      onSuccessColor = Color.fromARGB(255, 195, 230, 183);
    }
    else
    {
      successColor = Color.fromARGB(255, 195, 230, 183);
      onSuccessColor = Color(0xFF1C2717);
    }
  });
}

  @override
  void initState() {
    super.initState();
    getSavedJourneyRefreshTokens();
  }

  
Future<void> getSavedJourneyRefreshTokens() async {
  if (!mounted) return;
  
  print('RELOADING DATA - getSavedJourneyRefreshTokens called');
  
  // Set refreshing flag (don't clear data yet)
  setState(() {
    isRefreshing = true;
  });
  
  List<String> s = await Localdatasaver.getSavedJourneyRefreshTokens();
  
  if (!mounted) return;
  
  // Load new journeys without clearing old ones yet
  List<Journey> newJourneys = [];
  
  for (String token in s) {
    if (!mounted) return;
    
    try {
      Journey journey = await widget.page.services.refreshJourneyByToken(token);
      if (!mounted) return;
      
      newJourneys.add(journey);
    } catch (e) {
      print('Failed to load journey for token $token: $e');
    }
  }
  
  if (!mounted) return;
  
  newJourneys.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  DateTime now = DateTime.now();
  List<Journey> newFutureJourneys = [];
  List<Journey> newPastJourneys = [];

  for(Journey j in newJourneys)
  {
    if(j.arrivalTime.isAfter(now))
    {
      newFutureJourneys.add(j);
    }
    else
    {
      newPastJourneys.add(j);
    }
  }

  
  // Now update everything at once
  setState(() {
    savedJourneyrefreshTokens = s;
    savedJourneys = newJourneys;
    pastJourneys = newPastJourneys;
    futureJourneys = newFutureJourneys;
    isLoading = false;
    isRefreshing = false;
    print('Saved journeys reloaded: ${savedJourneys.length}');
  });
}

  @override
  void dispose() {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        _buildSearchBar(context),
        if(futureJourneys.isNotEmpty && !showingPastJourneys)
        _buildNextJourney(context),
        if(showingPastJourneys && pastJourneys.isNotEmpty)
        Center(child: Text('Past Journeys', style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),)),

        if(showingPastJourneys)
        Expanded(child: _buildJourneysList(context, pastJourneys)),
        if(!showingPastJourneys)
        Expanded(child: _buildJourneysList(context, futureJourneys)),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          elevation: MaterialStateProperty.all(0),
          controller: controller,
          hintText: 'Search saved journeys',
          trailing: <Widget>[
            Tooltip(
              message: "Filter your seach",
              child: IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  // Implement filter functionality here
                },
              ),
            ),
            if(cardView)
            Tooltip(
              message: "Switch to list view",
              child: IconButton(
                onPressed: () => {
                  setState(() {
                    cardView = false;
                  })
                }, 
                icon: Icon(Icons.list))
            ),
            if(!cardView)
            Tooltip(
              message: "Switch to card view",
              child: IconButton(
                onPressed: () => {
                  setState(() {
                    cardView = true;
                  })
                }, 
                icon: Icon(Icons.view_agenda_outlined))
            ),
            MenuAnchor(
  builder: (BuildContext context, MenuController controller, Widget? child) {
    return Tooltip(
      message: 'More Options',
      child: IconButton(
        icon: Icon(Icons.more_vert),
        onPressed: () {
          controller.open(); // this opens the menu
        },
      ),
    );
  },
  menuChildren: [
    MenuItemButton(
      onPressed: () {
        setState(() {
          if(showingPastJourneys){
            showingPastJourneys = false;
          }
          else
          {
            showingPastJourneys = true;
          }
        });
      },
      child: showingPastJourneys ? Text('Show Future Journeys') : Text('Show Past Journeys'),
    ),
    MenuItemButton(
      onPressed: () {},
      child: Text('Settings')
    )
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
    bool delayed = false;
    String delayText = 'no delays';
    String timeText = '';
    if(futureJourneys.isNotEmpty){
      timeText = generateJourneyTimeText(futureJourneys.first, false, false);
      if(futureJourneys.first.legs.first.departureDelayMinutes != null){
        delayed = true;
        delayText = 'Departure delayed';
      }
      if(futureJourneys.first.legs.last.arrivalDelayMinutes != null){
        if(delayed)
        {
          delayText = 'Delayed';
        }
        else{
          delayed = true;
          delayText = 'Arrival delayed';
        }
      }
    }
    Color delayColor = delayed
        ? Theme.of(context).colorScheme.errorContainer
        : successColor;
    
    Color onDelayColor = delayed
        ? Theme.of(context).colorScheme.onErrorContainer
        : onSuccessColor;


    return GestureDetector(
      onTap: () async {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Refreshing journey information...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );

            try {
              // Refresh the journey using the service
              final refreshedJourney = await widget.page.services
                  .refreshJourneyByToken(futureJourneys.first.refreshToken);

              // Close the loading dialog
              Navigator.pop(context);

              // Navigate to journey page with the refreshed journey
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JourneyPageAndroid(
                    JourneyPage(journey: refreshedJourney),
                    journey: refreshedJourney,
                  ),
                ),
              ).then((_) {
                getSavedJourneyRefreshTokens();
              });
            } catch (e) {
              // Close the loading dialog
              Navigator.pop(context);

              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not refresh journey: ${e.toString()}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );

              // Navigate with the original journey as fallback
            }
          },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: EdgeInsetsGeometry.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Next Journey',
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Theme.of( context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                      
                    ),
                    Text(generateJourneyTimeText(futureJourneys.first, true, false), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of( context).colorScheme.onPrimaryContainer)),
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
                  child: _buildCardView(context, futureJourneys.first, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildModes(BuildContext context, Journey journey, Color color) {
  List<String> products = [];
  for (Leg leg in journey.legs) {
    if (leg.product != null && leg.product!.isNotEmpty) {
      products.add(leg.product!);
    }
  }
  
  // Build list of widgets for the row
  List<Widget> modeWidgets = [];
  for (int index = 0; index < products.length; index++) {
    if (index > 0) {
      // Add chevron between modes
      modeWidgets.add(Icon(Icons.chevron_right, color: color, size: 20));
    }
    modeWidgets.add(Icon(
      getModeIcon(products[index]).icon,
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

  Icon getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'bus':
        return Icon(Icons.directions_bus);
      case 'nationalExpress':
        return Icon(Icons.train);
      case 'national':
        return Icon(Icons.train);
      case 'regional':
        return Icon(Icons.directions_railway);
      case 'regionalExpress':
        return Icon(Icons.directions_railway);
      case 'suburban':
        return Icon(Icons.directions_subway);
      case 'subway':
        return Icon(Icons.subway_outlined);
      case 'tram':
        return Icon(Icons.tram);
      case 'taxi':
        return Icon(Icons.local_taxi);
      case 'ferry':
        return Icon(Icons.directions_boat);
      default:
        return Icon(Icons.train);
    }
  }

Widget _buildJourneysList(BuildContext context, List<Journey> journeysList) {
  if(journeysList.isEmpty) {
    return Center(
      child: showingPastJourneys ?
        Text('No past journeys', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
        : Text('No saved journeys', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  List<Journey> journeys = List.from(journeysList);
  if(!showingPastJourneys) {
    journeys.removeAt(0);
  }
  
  if (journeys.isEmpty && !showingPastJourneys) {
    return Center(
      child: Text('No more saved journeys', style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  // Group journeys by date
  List<List<Journey>> journeysByDate = [];
  for(int i = 0; i < journeys.length; i++) {
    if(i == 0) {
      journeysByDate.add([journeys[i]]);
    } else {
      DateTime previous = journeys[i-1].plannedDepartureTime;
      if(journeys[i].plannedDepartureTime.day == previous.day &&
         journeys[i].plannedDepartureTime.month == previous.month &&
         journeys[i].plannedDepartureTime.year == previous.year) {
        journeysByDate.last.add(journeys[i]);
      } else {
        journeysByDate.add([journeys[i]]);
      }
    }
  }

  // Ensure isExpandedList matches journeysByDate length
  if (isExpandedList.length != journeysByDate.length) {
    isExpandedList = List<bool>.filled(journeysByDate.length, false);
  }

  return ListView.separated(
    padding: EdgeInsets.symmetric(vertical: 16.0),
    itemCount: journeysByDate.length,
    separatorBuilder: (context, index) => SizedBox(height: 12.0),
    itemBuilder: (context, index) {
      List<Journey> journeyGroup = journeysByDate[index];
      bool isExpanded = isExpandedList[index];
      
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isExpanded ? Theme.of(context).colorScheme.tertiaryContainer : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Column(
          children: [
            // Animated Header
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpandedList[index] = !isExpandedList[index];
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  borderRadius: isExpanded 
                    ? BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      )
                    : BorderRadius.circular(24.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 300),
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: isExpanded ? Theme.of(context).colorScheme.onTertiaryContainer : Theme.of(context).colorScheme.onSurface ),
                        child: Text(generateJourneyTimeText(journeyGroup.first, true, false)),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: isExpanded ? Theme.of(context).colorScheme.tertiary:Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 4.0),
                          AnimatedDefaultTextStyle(
                            duration: Duration(milliseconds: 300),
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: isExpanded ? Theme.of(context).colorScheme.onTertiary : Theme.of(context).colorScheme.onSurface,
                            ),
                            child: Text('${journeyGroup.length}'),
                          ),
                          
                          SizedBox(width: 4.0),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: isExpanded ? Theme.of(context).colorScheme.onTertiary : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Animated Expandable Body
            AnimatedSize(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: isExpanded ? null : 0,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: isExpanded ? 400 : 200),
                  opacity: isExpanded ? 1.0 : 0.0,
                  curve: isExpanded ? Curves.easeIn : Curves.easeOut,
                  child: isExpanded ? Column(
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
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                              Container(
                                height: 1,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer,
                                borderRadius: isLast ? BorderRadius.only(
                                  bottomLeft: Radius.circular(24.0),
                                  bottomRight: Radius.circular(24.0),
                                ) : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: isLast ? BorderRadius.only(
                                    bottomLeft: Radius.circular(24.0),
                                    bottomRight: Radius.circular(24.0),
                                  ) : null,
                                  onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Refreshing journey information...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
      
              try {
                // Refresh the journey using the service
                final refreshedJourney = await widget.page.services
                    .refreshJourneyByToken(journey.refreshToken);
      
                // Close the loading dialog
                Navigator.pop(context);
      
                // Navigate to journey page with the refreshed journey
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JourneyPageAndroid(
                      JourneyPage(journey: refreshedJourney),
                      journey: refreshedJourney,
                    ),
                  ),
                ).then((_) {
                  getSavedJourneyRefreshTokens();
                });
              } catch (e) {
                // Close the loading dialog
                Navigator.pop(context);
      
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not refresh journey: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
      
                // Navigate with the original journey as fallback
              }
            },
                                  child: cardView ? _buildCardView(context, journey, false) : _buildListView(context, journey),
                                ),
                              ),
                            ),
                            // Add separator line between items (except for last item)
                          ],
                        ),
                      );
                    }).toList(),
                  ) : SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildCardView(BuildContext context, Journey  journey, bool isFirst)
  {
    bool delayed = false;
    String timeText = '';
    Text liveTimeTextP1 = Text('');
    Text liveTimeTextP2 = Text('');
    timeText = generateJourneyTimeText(journey, false, true);
    Color yLight = Color.fromARGB(255, 229, 241, 116);
    Color yDark = Color.fromARGB(255, 166, 175, 34);
    Color y = yLight;
    Color g = onSuccessColor;
    if(Theme.of(context).brightness == Brightness.dark)
    {
      if(isFirst)
      {
        y = yDark;
      }
      else
      {
        y = yLight;
      }
    }
    else
    {
      if(isFirst)
      {
        y = yLight;
      }
      else
      {
        y = yDark;
      }
    }
    if(isFirst)
    {
      g = successColor;
    }

    if(journey.legs.first.departureDelayMinutes != null){
      delayed = true;
      Color c = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
      c = journey.legs.first.departureDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : c;
      liveTimeTextP1 = Text(generateLiveTimeText(journey, true, false), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),);
      liveTimeTextP2 = Text('');
    }
    if(journey.legs.last.arrivalDelayMinutes != null){
      if(delayed)
      {
        Color cD = journey.legs.last.departureDelayMinutes! <= 0 ? g : y;
        cD = journey.legs.last.departureDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : cD;
        Color cA = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        cA = journey.legs.last.arrivalDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : cA;
        liveTimeTextP1 = Text(generateLiveTimeText(journey, true, false), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cD),);
        liveTimeTextP2 = Text(generateLiveTimeText(journey, false, true), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cA),);
      }
      else{
        delayed = true;
        Color c = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        c = journey.legs.last.arrivalDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : c;
        liveTimeTextP2 = Text(generateLiveTimeText(journey, false, true), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),);
        liveTimeTextP1 = Text('          ', style: Theme.of(context).textTheme.bodyMedium,);
      }
    }
    return Padding(
      padding: isFirst ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: GestureDetector(
        onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Refreshing journey information...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
      
              try {
                // Refresh the journey using the service
                final refreshedJourney = await widget.page.services
                    .refreshJourneyByToken(journey.refreshToken);
      
                // Close the loading dialog
                Navigator.pop(context);
      
                // Navigate to journey page with the refreshed journey
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JourneyPageAndroid(
                      JourneyPage(journey: refreshedJourney),
                      journey: refreshedJourney,
                    ),
                  ),
                ).then((_) {
                  getSavedJourneyRefreshTokens();
                });
              } catch (e) {
                // Close the loading dialog
                Navigator.pop(context);
      
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not refresh journey: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
      
                // Navigate with the original journey as fallback
              }
            },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isFirst ? 16 : 16.0, horizontal:16),
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
                            color: isFirst ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                                child: Text(
                                  maxLines: 2,
                                    journey.legs.first.origin.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          color: isFirst ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              )
                        ],
                      ),
                      
                      SvgPicture.asset("assets/Icon/go_to_line.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
              isFirst ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
              BlendMode.srcIn,
            ),
                      ),
                      
                      Row(
                        children: [
                          SvgPicture.asset("assets/Icon/distance.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
              isFirst ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
              BlendMode.srcIn,
            ),
                      ),
                          SizedBox(width: 8),
                          Flexible(
                                child: Text(
                                  maxLines: 2,
                                    journey
                                        .legs
                                        .last
                                        .destination
                                        .name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          color: isFirst ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              )
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, color: isFirst ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,),
                          SizedBox(width: 8),
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
                                                color: isFirst ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
                                                fontWeight: FontWeight.bold
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                                      if(delayed)
                                      Row(
                                        children: [
                                          liveTimeTextP1,
                                          Text(
                                            ' - ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: isFirst ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
                                                  fontWeight: FontWeight.bold
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
                          _buildModes(context, journey, isFirst ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer),
                          Spacer(),
                          FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .errorContainer,
                      ),
                      onPressed: () => {},
                      label: Text('no Ticket', style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          )),
                      iconAlignment: IconAlignment.end,
                      icon: SvgPicture.asset("assets/Icon/transit_ticket.svg",
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
      ),
    );
  }

  String _findHighestMode(Journey journey)
  {
    String currentHighest = 'walk';
    for(Leg l in journey.legs)
    {
      if(l.product != null && l.product!.isNotEmpty)
      {
        if(modeIsHigher(currentHighest, l.product!))
        {
          currentHighest = l.product!;
        }
      }
    }
    return currentHighest;
  }

  bool modeIsHigher(String compareMode, String newMode)
  {
    List<String> modes = ['walk', 'taxi', 'bus', 'tram', 'ferry', 'subway', 'suburban', 'regional', 'regionalExpress', 'national', 'nationalExpress'];
    int compareIndex = modes.indexOf(compareMode.toLowerCase());
    int newIndex = modes.indexOf(newMode.toLowerCase());
    return newIndex > compareIndex;
  }

  Widget _buildListView(BuildContext context, Journey journey)
  {
    bool delayed = false;
    String timeText = '';
    timeText = generateJourneyTimeText(journey, false, true);
    Text liveTimeTextP1 = Text('');
    Text liveTimeTextP2 = Text('');
    Icon modeIcon = Icon(Icons.train, color: Theme.of(context).colorScheme.tertiary);
    String highestMode = _findHighestMode(journey);
    modeIcon = Icon(getModeIcon(highestMode).icon, color: Theme.of(context).colorScheme.tertiary,);
    if(journey.legs.first.departureDelayMinutes != null || journey.legs.last.arrivalDelayMinutes != null){
      delayed = true;
    }
    Color y = Theme.of(context).brightness == Brightness.dark ? Color.fromARGB(255, 229, 241, 116) : Color.fromARGB(255, 166, 175, 34);
    Color g = onSuccessColor;

    if(journey.legs.first.departureDelayMinutes != null){
      delayed = true;
      Color c = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
      c = journey.legs.first.departureDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : c;
      liveTimeTextP1 = Text(generateLiveTimeText(journey, true, false), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),);
      liveTimeTextP2 = Text('');
    }
    if(journey.legs.last.arrivalDelayMinutes != null){
      if(delayed)
      {
        Color cD = journey.legs.last.departureDelayMinutes! <= 0 ? g : y;
        cD = journey.legs.last.departureDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : cD;
        Color cA = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        cA = journey.legs.last.arrivalDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : cA;
        liveTimeTextP1 = Text(generateLiveTimeText(journey, true, false), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cD),);
        liveTimeTextP2 = Text(generateLiveTimeText(journey, false, true), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cA),);
      }
      else{
        delayed = true;
        Color c = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        c = journey.legs.last.arrivalDelayMinutes! >= 15 ? Theme.of(context).colorScheme.error : c;
        liveTimeTextP2 = Text(generateLiveTimeText(journey, false, true), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),);
        liveTimeTextP1 = Text('        ', style: Theme.of(context).textTheme.bodyMedium,);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Refreshing journey information...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
      
              try {
                // Refresh the journey using the service
                final refreshedJourney = await widget.page.services
                    .refreshJourneyByToken(journey.refreshToken);
      
                // Close the loading dialog
                Navigator.pop(context);
      
                // Navigate to journey page with the refreshed journey
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JourneyPageAndroid(
                      JourneyPage(journey: refreshedJourney),
                      journey: refreshedJourney,
                    ),
                  ),
                ).then((_) {
                  getSavedJourneyRefreshTokens();
                });
              } catch (e) {
                // Close the loading dialog
                Navigator.pop(context);
      
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not refresh journey: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
      
                // Navigate with the original journey as fallback
              }
            },
          leading: modeIcon,
          title: Text(
            '${journey.legs.first.origin.name} - ${journey.legs.last.destination.name}',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold
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
              SizedBox(width: 8),
              if(delayed)
                  liveTimeTextP1,
                  if(delayed)
                  Text(
                    ' - ',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if(delayed)
                  liveTimeTextP2, 
              
            ],
          ),
          trailing: IconButton(onPressed: ()=>{}, icon: SvgPicture.asset("assets/Icon/transit_ticket.svg",
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(
                                                  Theme.of(context).colorScheme.onErrorContainer,
                                                  BlendMode.srcIn,
                                                ),
                                    ),),
        ),
      ],
    );
  }

  String generateLiveTimeText(Journey journey, bool onlyDeparture, bool onlyArrival)
  {
    DateTime departureTime = journey.departureTime.toLocal();
    DateTime arrivalTime = journey.arrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');
    if(onlyDeparture)
    {
      return ('$departureHour:$departureMinute');
    }
    if(onlyArrival)
    {
      return ('$arrivalHour:$arrivalMinute');
    }
    return ('$departureHour:$departureMinute - $arrivalHour:$arrivalMinute'); 
  }

  String generateJourneyTimeText(Journey journey, bool onlyDate, bool onlyTime)
  {
    DateTime currentTime = DateTime.now();
    DateTime departureTime = journey.plannedDepartureTime.toLocal();
    DateTime arrivalTime = journey.plannedArrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');
    if(onlyTime)
    {
      return ('$departureHour:$departureMinute - $arrivalHour:$arrivalMinute');
    }
    if(departureTime.difference(currentTime).inDays < 3)
    {
      if(onlyDate && onlyTime)
      {
        onlyDate = false;
        onlyTime = false;
      }
      
      if(departureTime.day == currentTime.day)
      {
        if(onlyDate)
        {
          return 'Today';
        }
        return 'Today $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      }
      else if(departureTime.day == currentTime.day + 1)
      {
        if(onlyDate)
        {
          return 'Tomorrow';
        }
        return 'Tomorrow $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      }
    }
    if(departureTime.subtract(Duration(days: 7)).isBefore(currentTime))
    {
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
      if(onlyDate)
      {
        return 'next $weekdayName';
      }
      return 'next $weekdayName $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }
    else
    {
      if(onlyDate)
      {
        return '${departureTime.day}.${departureTime.month}.${departureTime.year}';
      }
      return '${departureTime.day}.${departureTime.month}.${departureTime.year} $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }
  }

  void reloadData()
  {
    setState(() {
      savedJourneys.clear();
      getSavedJourneyRefreshTokens();
    });
  }

  void sortJourneysbyDepartureTime() {
    savedJourneys.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }

  void sortFutureJourneysbyDepartureTime() {
    futureJourneys.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }

  void sortPastJourneysbyDepartureTime() {
    pastJourneys.sort((a, b) => b.departureTime.compareTo(a.departureTime));
  }
}
