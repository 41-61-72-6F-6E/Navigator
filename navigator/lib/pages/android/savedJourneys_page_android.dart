import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/localDataSaver.dart';

class SavedjourneysPageAndroid extends StatefulWidget {
  final SavedjourneysPage page;

  SavedjourneysPageAndroid(this.page, {Key? key}) : super(key: key);

  @override
  State<SavedjourneysPageAndroid> createState() =>
      _SavedjourneysPageAndroidState();
}

class _SavedjourneysPageAndroidState extends State<SavedjourneysPageAndroid> {
  List<String> savedJourneyrefreshTokens = [];
  List<Journey> savedJourneys = [];

  @override
  void initState() {
    super.initState();
    getSavedJourneyRefreshTokens();
  }

  Future<void> getSavedJourneyRefreshTokens() async {
    List<String> s = await Localdatasaver.getSavedJourneyRefreshTokens();
    setState(() {
      savedJourneyrefreshTokens = s;
      print(
        'Saved journey refresh tokens loaded: ${widget.page.savedJourneyrefreshTokens}',
      );
    });
    for (String token in savedJourneyrefreshTokens) {
      Journey journey = await widget.page.services.refreshJourneyByToken(token);
      savedJourneys.add(journey);
    }
    sortJourneysbyDepartureTime();
    setState(() {
      savedJourneys = savedJourneys;
      print('Saved journeys loaded: ${savedJourneys.length}');
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
    if(savedJourneys.isNotEmpty){
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
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          savedJourneys.first.legs.first.origin.name,
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
                                    )
                                    : Flexible(
                                      child: Text(
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
                                    ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                SizedBox(width: 8),
                                savedJourneys.isNotEmpty
                                    ? Flexible(
                                      child: Text(
                                          savedJourneys
                                              .first
                                              .legs
                                              .last
                                              .destination
                                              .name,
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
                                    )
                                    : Flexible(
                                      child: Text(
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
                                    ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                SizedBox(width: 8),
                                savedJourneys.isNotEmpty
                                    ? Text(
                                        savedJourneys.first.departureTime
                                            .toLocal()
                                            .toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
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
                          //Spacer(),
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
                            icon: Icon(
                              Icons.airplane_ticket,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
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

  void sortJourneysbyDepartureTime() {
    savedJourneys.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }
}
