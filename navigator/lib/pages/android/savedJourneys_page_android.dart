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
  bool isLoading = false;
  bool isRefreshing = false;
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
  
  // Now update everything at once
  setState(() {
    savedJourneyrefreshTokens = s;
    savedJourneys = newJourneys;
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
        if(savedJourneys.isNotEmpty)
        _buildNextJourney(context),
        _buildJourneysList(context),
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
    if(savedJourneys.isNotEmpty){
      timeText = generateJourneyTimeText(savedJourneys.first);
      if(savedJourneys.first.legs.first.departureDelayMinutes != null){
        delayed = true;
        delayText = 'Departure delayed';
      }
      if(savedJourneys.first.legs.last.arrivalDelayMinutes != null){
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
                  .refreshJourneyByToken(savedJourneys.first.refreshToken);

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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsetsGeometry.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Next Journey',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Theme.of( context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                  
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(16),
                elevation: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trip_origin,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    SizedBox(width: 8),
                                    savedJourneys.isNotEmpty
                                        ? Flexible(
                                          child: Text(
                                            maxLines: 2,
                                              savedJourneys.first.legs.first.origin.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        )
                                        : Flexible(
                                          child: Text(
                                              'No saved journeys',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ),
                                  ],
                                ),
                                
                                SvgPicture.asset("assets/Icon/go_to_line.svg",
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onPrimary,
                        BlendMode.srcIn,
                      ),
                                ),
                                
                                Row(
                                  children: [
                                    SvgPicture.asset("assets/Icon/distance.svg",
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onPrimary,
                        BlendMode.srcIn,
                      ),
                                ),
                                    SizedBox(width: 8),
                                    savedJourneys.isNotEmpty
                                        ? Flexible(
                                          child: Text(
                                            maxLines: 2,
                                              savedJourneys
                                                  .first
                                                  .legs
                                                  .last
                                                  .destination
                                                  .name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        )
                                        : Flexible(
                                          child: Text(
                                              'No saved journeys',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    SvgPicture.asset("assets/Icon/calendar_clock.svg",
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onPrimary,
                        BlendMode.srcIn,
                      ),
                                ),
                                    SizedBox(width: 8),
                                    savedJourneys.isNotEmpty
                                        ? Text(
                                            timeText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : Text(
                                            'No saved journeys',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildModes(context, savedJourneys.first, Theme.of(context).colorScheme.onPrimary),
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
                              
                              FilledButton.tonalIcon(onPressed: ()=>showDelayInfo(context, savedJourneys.first), 
                                label: Text(delayText, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: onDelayColor),),
                                iconAlignment: IconAlignment.end,
                                icon: Icon(Icons.more_time, color: onDelayColor,),
                                style: FilledButton.styleFrom(
                                  backgroundColor: delayColor,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildJourneysList(BuildContext context) {
    if(savedJourneys.isEmpty) {
      return Center(
        child: Text(
          'No saved journeys',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
    }
    List<Journey> journeys = List.from(savedJourneys);
    journeys.removeAt(0);
    if (journeys.isEmpty) {
      return Center(
        child: Text(
          'No more saved journeys',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
    }

    return Expanded(
      child: Container(
        padding: cardView ? EdgeInsets.all(0) : EdgeInsets.only(top: 8),
        
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.builder(
          itemCount: journeys.length,
          itemBuilder: (context, index)
          {
            final journey = journeys[index];
            return cardView ?
              _buildCardView(context, journey) :
              _buildListView(context, journey);
          }
              )),
    );


  }

  Widget _buildCardView(BuildContext context, Journey  journey)
  {
    bool delayed = false;
    String delayText = 'no delays';
    String timeText = '';
    timeText = generateJourneyTimeText(journey);
    if(journey.legs.first.departureDelayMinutes != null){
      delayed = true;
      delayText = 'Departure delayed';
    }
    if(journey.legs.last.arrivalDelayMinutes != null){
      if(delayed)
      {
        delayText = 'Delayed';
      }
      else{
        delayed = true;
        delayText = 'Arrival delayed';
      }
    }
    
    Color delayColor = delayed
        ? Theme.of(context).colorScheme.errorContainer
        : successColor;
    
    Color onDelayColor = delayed
        ? Theme.of(context).colorScheme.onErrorContainer
        : onSuccessColor;
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trip_origin,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimaryContainer,
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
                          Theme.of(context).colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                                  ),
                                  
                                  Row(
                                    children: [
                                      SvgPicture.asset("assets/Icon/distance.svg",
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onPrimaryContainer,
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
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimaryContainer,
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
                                      SvgPicture.asset("assets/Icon/calendar_clock.svg",
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                                  ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                                timeText,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimaryContainer,
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildModes(context, journey, Theme.of(context).colorScheme.onPrimaryContainer),
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
                                
                                FilledButton.tonalIcon(onPressed: ()=>showDelayInfo(context, journey), 
                                  label: Text(delayText, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: onDelayColor),),
                                  iconAlignment: IconAlignment.end,
                                  icon: Icon(Icons.more_time, color: onDelayColor,),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: delayColor,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
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
    timeText = generateJourneyTimeText(journey);
    Icon modeIcon = Icon(Icons.train, color: Theme.of(context).colorScheme.tertiary);
    String highestMode = _findHighestMode(journey);
    modeIcon = Icon(getModeIcon(highestMode).icon, color: Theme.of(context).colorScheme.tertiary,);
    if(journey.legs.first.departureDelayMinutes != null || journey.legs.last.arrivalDelayMinutes != null){
      delayed = true;
    }
    
    Color onDelayColor = delayed
        ? Theme.of(context).colorScheme.onErrorContainer
        : successIconColor;
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
          subtitle: Text(
            timeText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            IconButton(onPressed: ()=>showDelayInfo(context, journey), icon: Icon(Icons.more_time), color: onDelayColor,),
            IconButton(onPressed: ()=>{}, icon: SvgPicture.asset("assets/Icon/transit_ticket.svg",
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                                    Theme.of(context).colorScheme.onErrorContainer,
                                                    BlendMode.srcIn,
                                                  ),
                                      ),)
          ],),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Divider(
            color: Theme.of(context).colorScheme.outline,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  void showDelayInfo(BuildContext context, Journey journey)
  {
    Color arrivalColor = journey.legs.last.arrivalDelayMinutes != null
        ? Theme.of(context).colorScheme.error
        : successIconColor;

    Color departureColor = journey.legs.first.departureDelayMinutes != null
        ? Theme.of(context).colorScheme.error
        : successIconColor;

    showDialog(context: context, builder: (BuildContext context)
    {
      return AlertDialog(
        title: Text('Delay Information', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Departure Delay: ', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface),),
            Text(journey.legs.first.departureDelayMinutes != null ? '${journey.legs.first.departureDelayMinutes} minutes' : 'No delay', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: departureColor),),
            SizedBox(height: 8),
            Text('Arrival Delay: ', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface),),
            Text(journey.legs.last.arrivalDelayMinutes != null ? '${journey.legs.last.arrivalDelayMinutes} minutes' : 'No delay', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: arrivalColor),),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.primary)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  String generateJourneyTimeText(Journey journey)
  {
    DateTime currentTime = DateTime.now();
    DateTime departureTime = journey.departureTime.toLocal();
    DateTime arrivalTime = journey.arrivalTime.toLocal();
    String departureHour = departureTime.hour.toString().padLeft(2, '0');
    String departureMinute = departureTime.minute.toString().padLeft(2, '0');
    String arrivalHour = arrivalTime.hour.toString().padLeft(2, '0');
    String arrivalMinute = arrivalTime.minute.toString().padLeft(2, '0');
    if(departureTime.difference(currentTime).inDays < 3)
    {
      if(departureTime.day == currentTime.day)
      {
        return 'Today $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
      }
      else if(departureTime.day == currentTime.day + 1)
      {
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
      return 'next $weekdayName $departureHour:$departureMinute - $arrivalHour:$arrivalMinute';
    }
    else
    {
      return '${departureTime.day}.${departureTime.month}.${departureTime.year} ${departureTime.hour}:${departureTime.minute} - ${arrivalTime.hour}:${arrivalTime.minute}';
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
}
