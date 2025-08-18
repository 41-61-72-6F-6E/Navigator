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

  @override
void didUpdateWidget(SavedjourneysPageAndroid oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Force reload when widget updates
  WidgetsBinding.instance.addPostFrameCallback((_) {
    getSavedJourneyRefreshTokens();
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
        : Theme.of(context).colorScheme.primaryContainer;
    
    Color onDelayColor = delayed
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;


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
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Card(
                elevation: 10,
                color: Theme.of(context).colorScheme.primary,
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
                            _buildModes(context),
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
                            
                            FilledButton.tonalIcon(onPressed: ()=>{}, 
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModes(BuildContext context) {
    return Container();
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
    return Container();
  }

  Widget _buildBody(BuildContext context) {
    return ListView.builder(
      itemCount: savedJourneyrefreshTokens.length,
      itemBuilder: (context, index) {
        final journey = savedJourneyrefreshTokens[index];
        return ListTile(
          title: Text(journey),
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
                  .refreshJourneyByToken(journey);

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
              );
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
        );
      },
    );
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
