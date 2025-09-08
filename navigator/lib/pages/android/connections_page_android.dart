import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/android/shared_bottom_navigation_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'dart:math' as math;

import '../../models/journeySettings.dart';

class ConnectionsPageAndroid extends StatefulWidget {
  final ConnectionsPage page;

  const ConnectionsPageAndroid(this.page, {super.key});
  @override
  State<ConnectionsPageAndroid> createState() => _ConnectionsPageAndroidState();
}

class _ConnectionsPageAndroidState extends State<ConnectionsPageAndroid> {
  //Variables

  late final TextEditingController _toController;
  late final TextEditingController _fromController;
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  List<Journey>? _currentJourneys;
  late List<Location> _searchResultsFrom;
  late List<Location> _searchResultsTo;
  String _lastSearchedText = '';
  Timer? _debounce;
  late FocusNode _fromFocusNode;
  late FocusNode _toFocusNode;
  bool departure = true;
  bool searching = false;
  bool searchingFrom = true;
  List<FavoriteLocation> faves = [];


  //Animations
  bool rotateSwitchButton = false;
  bool inJourneySearchAnimation = false;
  double rotatingSearchIconTurns = 0;

  JourneySettings journeySettings = JourneySettings(
    nationalExpress: true,
    national: true,
    regionalExpress: true,
    regional: true,
    suburban: true,
    subway: true,
    tram: true,
    bus: true,
    ferry: true,
    deutschlandTicketConnectionsOnly: false,
    accessibility: false,
    walkingSpeed: 'normal',
    transferTime: null, // Default to null for no minimum transfer time
  );

  @override
  void initState() {
    super.initState();
    //Initializers
    updateLocationWithCurrentPosition(true, true);
    _fromFocusNode = FocusNode();
    _toFocusNode = FocusNode();
    _toController = TextEditingController(text: widget.page.to.name);
    _fromController = TextEditingController(text: 'Current Location');
    _selectedTime = TimeOfDay.now();
    _selectedDate = DateTime.now();
    _searchResultsFrom = [];
    _searchResultsTo = [];

    _fromFocusNode.addListener(() {
      if (!_fromFocusNode.hasFocus) {
        setState(() {
          _searchResultsFrom.clear();
          searching = false;
        });
      }
    });

    _toFocusNode.addListener(() {
      if (!_toFocusNode.hasFocus) {
        setState(() {
          _searchResultsTo.clear();
          searching = false;
        });
      }
    });

    _fromFocusNode.addListener(() {
      if (_fromFocusNode.hasFocus) {
        setState(() {
          searching = true;
          searchingFrom = true;
        });
      }
    });

    _toFocusNode.addListener(() {
      if (_toFocusNode.hasFocus) {
        setState(() {
          searching = true;
          searchingFrom = false;
        });
      }
    });

    _toController.addListener(() {
      _onSearchChanged(_toController.text.trim(), false);
    });

    _fromController.addListener(() {
      _onSearchChanged(_fromController.text.trim(), true);
    });
    _getFaves();
  }

  //Helper Functions
  void _onSearchChanged(String query, bool from) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query != _lastSearchedText) {
        getSearchResults(query, from);
        _lastSearchedText = query;
      }
    });
  }

  //async to Sync functions
  Future<void> updateLocationWithCurrentPosition(bool from, bool startSearchWhenFinished) async {
    try {
      // Update the from location if needed
      Location l = await widget.page.services.getCurrentLocation();
      setState(()
      {
        if(from){
        widget.page.from = l;
        }
        else {
          widget.page.to = l;
        }
      });
      if(startSearchWhenFinished)
      {
        _search();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> getSearchResults(String query, bool from) async {
    final results = await widget.page.services.getLocations(query);
    if (from) {
      setState(() {
        _searchResultsFrom = results;
      });
    } else {
      setState(() {
        _searchResultsTo = results;
      });
    }
  }

  Future<void> getJourneys(
    String fromId,
    String toId,
    double fromLat,
    double fromLon,
    double toLat,
    double toLong,
    DateAndTime when,
    bool departure,
  ) async {
    try {
      print('Getting journeys with params:');
      print('From: $fromId ($fromLat, $fromLon)');
      print('To: $toId ($toLat, $toLong)');

      // Build Location objects
      final from = Location(
        id: fromId,
        latitude: fromLat,
        longitude: fromLon,
        name: widget.page.from.name,
        type: widget.page.from.type,
        address: null,
      );

      final to = Location(
        id: toId,
        latitude: toLat,
        longitude: toLong,
        name: widget.page.to.name,
        type: widget.page.to.type,
        address: null,
      );

      final journeys = await widget.page.services.getJourneys(
        from,
        to,
        when,
        departure,
        journeySettings: journeySettings,
      );

      print('Received ${journeys.length} journeys');

      setState(() {
        _currentJourneys = journeys;
        inJourneySearchAnimation = false;
      });
    } catch (e) {
      print('Error getting journeys: $e');
      setState(() {
        _currentJourneys = [];
        inJourneySearchAnimation = false; // Empty list to show "no results"
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //Input Fields
              _buildInputFields(context),

              SizedBox(height: 16),

              //Search related Buttons

              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (child, anim)
                  {
                     return FadeTransition(opacity:anim, child: child);
                  },
                child: searching ? _buildFaves(context, searchingFrom) : _buildButtons(context)
              ),

              //Results
              if (searching)
                Expanded(child: _buildSearchResults(context, searchingFrom)),

              if (!searching) _buildJourneys(context),
            ],
          ),
        ),
      ),
            bottomNavigationBar: SharedBottomNavigation(),
    );
  }

  Widget _buildInputFields(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          width: 1,
          color: colors.outline,
        ),
        color: colors.secondaryContainer,
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: TextField(
                    controller: _fromController,
                    focusNode: _fromFocusNode,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      fillColor: colors.surface,
                      filled: true,
                      labelText: 'From',
                      labelStyle: TextStyle(color: colors.onSurface),
                      prefixIcon: GestureDetector(
                        onTap: () async {
                          // Unfocus the text field first
                          _fromFocusNode.unfocus();

                          // Get current location and update the from field
                          await updateLocationWithCurrentPosition(true, false);

                          // Update the controller and state
                          _fromController.text =
                              "Current Location"; // This should probably be widget.page.from.name
                          // Don't set widget.page.from = widget.page.from (redundant)
                        },
                        child: Icon(Icons.location_on, color: colors.onSurface),
                      ),
                      border: OutlineInputBorder().copyWith(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        searching = true;
                        searchingFrom = true;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: TextField(
                    controller: _toController,
                    focusNode: _toFocusNode,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      fillColor: colors.surface,
                      filled: true,
                      labelText: 'To',
                      labelStyle: TextStyle(color: colors.onSurface),
                      prefixIcon: GestureDetector(
                        onTap: () async {
                          // Unfocus the text field first
                          _toFocusNode.unfocus();

                          // Get current location and update the to field
                          await updateLocationWithCurrentPosition(false, false);

                          // Update the controller and state - FIX: use correct field
                          _toController.text =
                              "Current Location"; // This should probably be widget.page.to.name
                          //widget.page.to = widget.page.from; // This should probably be widget.page.to = currentLocation
                        },
                        child: Icon(Icons.location_on, color: colors.onSurface),
                      ),
                      border: OutlineInputBorder().copyWith(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        searching = true;
                        searchingFrom = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedRotation(
                  turns: rotateSwitchButton ? 0.5 : 0.0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.primary,
                      iconSize: 32,
                      side: BorderSide(
                        color: colors.outline,
                        width: 1,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        rotateSwitchButton = !rotateSwitchButton;
                      });
                      // Swap the controllers' text
                      String temp = _fromController.text;
                      _fromController.text = _toController.text;
                      _toController.text = temp;
                  
                      // Also swap the page data
                      var tempLocation = widget.page.from;
                      widget.page.from = widget.page.to;
                      widget.page.to = tempLocation;
                    },
                    icon: Icon(Icons.swap_vert),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationResult(BuildContext context, Station station) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainerHighest,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        child: InkWell(
          onTap: () {
            setState(() {
              if (searchingFrom) {
                widget.page.from = station;
                _fromController.text = station.name;
                _fromFocusNode.unfocus();
              } else {
                widget.page.to = station;
                _toController.text = station.name;
                _toFocusNode.unfocus();
              }
              
            });
            _search();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Tonal avatar for the station icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.tertiaryContainer,
                  child: SvgPicture.asset(
                    "assets/Icon/Train_Station_Icon.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colors.onTertiaryContainer,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
        
                // Station name + service icons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (station.national || station.nationalExpress)
                            Icon(Icons.train, size: 20, color: colors.tertiary),
                          if (station.regionalExpress)
                            Icon(
                              Icons.directions_railway,
                              size: 20,
                              color: colors.tertiary,
                            ),
                          if (station.regional)
                            Icon(
                              Icons.directions_transit,
                              size: 20,
                              color: colors.tertiary,
                            ),
                          if (station.suburban)
                            Icon(
                              Icons.directions_subway,
                              size: 20,
                              color: colors.tertiary,
                            ),
                          if (station.bus)
                            Icon(
                              Icons.directions_bus,
                              size: 20,
                              color: colors.tertiary,
                            ),
                          if (station.ferry)
                            Icon(
                              Icons.directions_ferry,
                              size: 20,
                              color: colors.tertiary,
                            ),
                          if (station.subway)
                            Icon(Icons.subway, size: 20, color: colors.tertiary),
                          if (station.tram)
                            Icon(Icons.tram, size: 20, color: colors.tertiary),
                          if (station.taxi)
                            Icon(
                              Icons.local_taxi,
                              size: 20,
                              color: colors.tertiary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                buildFavouriteButton(context, station),
        
                // Trailing chevron
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationResult(BuildContext context, Location location) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainerHighest,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          setState(() {
            if (searchingFrom) {
              widget.page.from = location;
              _fromController.text = location.name;
              _fromFocusNode.unfocus();
            } else {
              widget.page.to = location;
              _toController.text = location.name;
              _toFocusNode.unfocus();
            }
            
          });
          _search();
          
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tonal avatar for the “home” icon
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.tertiaryContainer,
                child: Icon(
                  Icons.house,
                  size: 24,
                  color: colors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // Location name
              Expanded(
                child: Text(
                  location.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              buildFavouriteButton(context, location),

              // Chevron affordance
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getFaves() async
  {
    List<FavoriteLocation> f = await Localdatasaver.getFavouriteLocations();
    setState(() {
      faves = f;
    });
  }

  Widget _buildFaves(BuildContext context, bool searchingFrom)
  {
    return Row(
    children: [
      if(faves.isEmpty)
      Icon(Icons.favorite),
      if(faves.isEmpty)
      SizedBox(width: 16,),
      if(faves.isEmpty)
        Text('No saved Locations so far', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),),
      if(faves.isNotEmpty)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: faves.map((f) => Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: IntrinsicWidth(
                  child: ActionChip(
                    label: Text(f.name, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),),
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                    onPressed: () => {
                      if(searchingFrom)
                      {
                        setState(() {
                          _fromController.text = f.name;
                          widget.page.from = f.location;
                          _fromFocusNode.unfocus();
                        }),
                        _search()
                      }
                      else
                      {
                        setState(() {
                          _toController.text = f.name;
                          widget.page.to = f.location;
                          _toFocusNode.unfocus();
                        }),
                        _search()
                      }
                    },
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        Spacer(),
        IconButton(onPressed: (){}, icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary,))
    ],
  );
  }

  Widget _buildSearchResults(BuildContext context, bool searchingFrom) {
    if (searchingFrom) {
      if (_searchResultsFrom.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      return ListView.builder(
        key: const ValueKey('list'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResultsFrom.length,
        itemBuilder: (context, i) {
          final r = _searchResultsFrom[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: r is Station
                ? _stationResult(context, r)
                : _locationResult(context, r),
          );
        },
      );
    } else {
      if (_searchResultsTo.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      return ListView.builder(
        key: const ValueKey('list'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResultsTo.length,
        itemBuilder: (context, i) {
          final r = _searchResultsTo[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: r is Station
                ? _stationResult(context, r)
                : _locationResult(context, r),
          );
        },
      );
    }
  }

  Widget _buildJourneys(BuildContext context) {
    if (_currentJourneys == null) {
      return Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (_currentJourneys!.isEmpty) {
      return Expanded(child: Center(child: Text('No journeys found')));
    }
    return Expanded(
      child: ListView.builder(
        key: const ValueKey('list'),
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: _currentJourneys!.length,
        itemBuilder: (context, i) {
          final r = _currentJourneys![i];
          return _buildJourneyCard(context, r);
        },
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, Journey j)
  {
    int shortestInterchangeInMinutes = 100;
    bool shouldShowShortInterchange = false;
    if(getShortestInterchange(j) != null)
    {
      shortestInterchangeInMinutes = getShortestInterchange(j)!;
      if(shortestInterchangeInMinutes <= 5)
      {
        shouldShowShortInterchange = true;
      }
    }
    String tripDuration = '';
    Duration tripD = j.legs.last.plannedArrivalDateTime.difference(j.legs.first.plannedDepartureDateTime);
    if(tripD.inMinutes < 60)
    {
      tripDuration = '${tripD.inMinutes} min';
    }
    else if(tripD.inHours < 24)
    {
      int minutes = tripD.inMinutes % 60;
      int hours = ((tripD.inMinutes - minutes) / 60).round();
      tripDuration = '${hours}h${minutes}m';
    }
    else
    {
      int minutes = tripD.inMinutes % 60;
      int hours = ((tripD.inMinutes - minutes) / 60).round() % 24;
      int days = (((tripD.inMinutes - (hours * 60))-minutes) /24).round();
      tripDuration = '${days}d${hours}h${minutes}m';
    }
    String plannedDepartureTimeHour = '${j.legs.first.plannedDepartureDateTime.toLocal().hour}'.padLeft(2, '0');
    String plannedDepartureTimeMinute = '${j.legs.first.plannedDepartureDateTime.toLocal().minute}'.padLeft(2,'0');
    String plannedArrivalTimeHour = '${j.legs.last.plannedArrivalDateTime.toLocal().hour}'.padLeft(2, '0');
    String plannedArrivalTimeMinute ='${j.legs.last.plannedArrivalDateTime.toLocal().minute}'.padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                );

                try {
                  // Refresh the journey using the service
                  final refreshedJourney = await widget.page.services
                      .refreshJourney(j);

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
                      content: Text(
                        'Could not refresh journey: ${e.toString()}',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );

                  // Navigate with the original journey as fallback
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JourneyPageAndroid(
                        JourneyPage(journey: j),
                        journey: j,
                      ),
                    ),
                  );
                }
              },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16)
          ),
          padding: EdgeInsets.all(8),
          child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16)
                ),
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Text('$plannedDepartureTimeHour:$plannedDepartureTimeMinute to $plannedArrivalTimeHour:$plannedArrivalTimeMinute', 
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary),),
                    Spacer(),
                    Text(tripDuration, style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary))
                  ],
                )
              ),
              Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 8),child: _buildModeLine(context, j),),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                          child: Row(
                            spacing: 4,
                            children: [
                              Icon(Icons.transfer_within_a_station, color: Theme.of(context).colorScheme.onTertiaryContainer, size: 16,),
                              SizedBox(width: 24,),
                              Text('${calculateTotalInterchanges(j)}', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),)
                            ],
                          ),
                        ),
                      ),
                      if(shouldShowShortInterchange)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            spacing: 4,
                            children: [
                              Icon(Icons.error, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
                              Text('short Transfer: $shortestInterchangeInMinutes min', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),)
                            ],
                          ),
                        )
                      )
                    ],
                  ),
                  
                ),
              )
            ],
          ),
        ),
      ),
    );
  }



Widget _buildModeLine(BuildContext context, Journey j) {
  int totalTripDuration = j.legs.last.plannedArrivalDateTime
      .difference(j.legs.first.plannedDepartureDateTime).inSeconds;
  List<String> legNames = [];
  List<double> legPercentages = [];
  List<String> legLineNames = [];
  
  // First, identify which legs are actual travel vs same-station interchanges (similar to _buildJourneyContent)
  List<int> actualLegIndices = [];
  
  for (int index = 0; index < j.legs.length; index++) {
    final leg = j.legs[index];
    
    // Skip legs that are same-station interchanges (same origin and destination)
    bool isSameStationInterchange =
        leg.origin.id == leg.destination.id &&
        leg.origin.name == leg.destination.name;
    
    // Also skip walking legs within the same station complex
    bool isWalkingWithinStationComplex = leg.isWalking == true &&
        leg.origin.ril100Ids.isNotEmpty &&
        leg.destination.ril100Ids.isNotEmpty &&
        _haveSameRil100ID(leg.origin.ril100Ids, leg.destination.ril100Ids);
    
    if (!isSameStationInterchange && !isWalkingWithinStationComplex) {
      actualLegIndices.add(index);
    }
  }
  
  // Process only actual legs for the mode line
  for (int i = 0; i < actualLegIndices.length; i++) {
    int legIndex = actualLegIndices[i];
    Leg l = j.legs[legIndex];
    
    if ((l.product == null || l.product!.isEmpty) && l.productName == null) {
      // Walking or transfer leg
      int legDuration = l.plannedArrivalDateTime.difference(l.plannedDepartureDateTime).inSeconds;
      double percentage = (legDuration / totalTripDuration) * 100;
      
      if (_haveSameRil100ID(l.origin.ril100Ids, l.destination.ril100Ids)) {
        legNames.add('transfer');
        legLineNames.add('');
      } else {
        legNames.add('walk');
        legLineNames.add('');
      }
      legPercentages.add(percentage);
    } else {
      // Regular transport leg
      int legDuration = l.plannedArrivalDateTime.difference(l.plannedDepartureDateTime).inSeconds;
      double percentage = (legDuration / totalTripDuration) * 100;
      
      if(l.product == null && l.productName != null)
      {
        legNames.add(l.productName!.toLowerCase());
      }
      else
      {
        legNames.add(l.product!);
      }
      legLineNames.add(l.lineName!);
      legPercentages.add(percentage);
    }
    
    // Add transfer time between actual legs if there's a gap and an interchange is needed
    if (i < actualLegIndices.length - 1) {
      int nextLegIndex = actualLegIndices[i + 1];
      Leg nextLeg = j.legs[nextLegIndex];
      
      // Check if there's an interchange between this leg and the next actual leg
      bool shouldShowTransfer = false;
      
      // Case 1: There are legs between current and next that represent interchanges
      if (nextLegIndex - legIndex > 1) {
        // Check for same-station interchanges between them
        for (int interchangeIndex = legIndex + 1; interchangeIndex < nextLegIndex; interchangeIndex++) {
          final interchangeLeg = j.legs[interchangeIndex];
          
          if (interchangeLeg.origin.id == interchangeLeg.destination.id &&
              interchangeLeg.origin.name == interchangeLeg.destination.name) {
            shouldShowTransfer = true;
            break;
          }
        }
      }
      // Case 2: Direct connection between different modes
      else if (l.destination.id == nextLeg.origin.id &&
          l.destination.name == nextLeg.origin.name &&
          ((l.isWalking == true && nextLeg.isWalking != true) ||
              (l.isWalking != true && nextLeg.isWalking == true) ||
              (l.isWalking != true &&
                  nextLeg.isWalking != true &&
                  l.lineName != nextLeg.lineName))) {
        shouldShowTransfer = true;
      }
      
      // Check if we're in the same station complex
      bool isWithinStationComplex =
          l.destination.ril100Ids.isNotEmpty &&
          nextLeg.origin.ril100Ids.isNotEmpty &&
          _haveSameRil100ID(l.destination.ril100Ids, nextLeg.origin.ril100Ids);
      
      if (isWithinStationComplex || shouldShowTransfer) {
        int transferTime = nextLeg.plannedDepartureDateTime
            .difference(l.plannedArrivalDateTime).inSeconds;
        if (transferTime > 0) {
          double transferPercentage = (transferTime / totalTripDuration) * 100;
          legNames.add('transfer');
          legLineNames.add('');
          legPercentages.add(transferPercentage);
        }
      }
    }
  }
  
  for (int i = 0; i < legNames.length; i++) {
    print(legNames[i] + legPercentages[i].toString());
  }
  
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16)
    ),
    clipBehavior: Clip.antiAlias,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(legNames.length, (index) {
            // Calculate actual width for this segment
            double segmentWidth = constraints.maxWidth * (legPercentages[index] / 100);
        Icon icon = Icon(Icons.directions_walk);
        bool light = Theme.of(context).brightness == Brightness.light;
        Color color = Colors.grey;
        Color onColor = light ? Colors.white : Colors.black;
        bool showText = true;
        String text = legLineNames[index];
        
        // Define minimum widths for showing content
        const double minWidthForIcon = 24.0; // Need at least 24px for icon
        const double minWidthForText = 60.0; // Need at least 60px for icon + text
        
        bool shouldShowIcon = segmentWidth >= minWidthForIcon;
        bool shouldShowTextContent = segmentWidth >= minWidthForText && showText;
        
        switch(legNames[index]) {
          case 'transfer':
            icon = Icon(Icons.transfer_within_a_station);
            showText = false;
            break;
          case 'walk':
            icon = Icon(Icons.directions_walk);
            showText = false;
            break;
          case 'bus':
            icon = Icon(Icons.directions_bus);
            color = light ? Colors.deepPurple : Colors.purpleAccent;
            break;
          case 'nationalExpress':
            icon = Icon(Icons.train);
            color = light ? Colors.black : Colors.white;
            break;
          case 'national':
            icon = Icon(Icons.train);
            color = light ? Colors.teal.shade900 : Colors.teal.shade300;
            break;
          case 'regional':
            icon = Icon(Icons.directions_railway);
            color = light ? Colors.yellow.shade900 : Colors.yellow.shade300;
            break;
          case 'regionalExpress':
            icon = Icon(Icons.directions_railway);
            color = light ? Colors.pink.shade900 : Colors.pink.shade300;
            break;
          case 'suburban':
            icon = Icon(Icons.directions_subway);
            color = light ? Colors.green.shade900 : Colors.green.shade300;
            break;
          case 'subway':
            icon = Icon(Icons.subway_outlined);
            color = light ? Colors.blue.shade900 : Colors.blue.shade300;
            break;
          case 'tram':
            icon = Icon(Icons.tram);
            color = light ? Colors.deepOrange.shade900 : Colors.deepOrange.shade300;
            break;
          case 'taxi':
            icon = Icon(Icons.local_taxi);
            color = light ? Colors.amber.shade300 : Colors.amber.shade700;
            break;
          case 'ferry':
            icon = Icon(Icons.directions_boat);
            color = light ? Colors.cyan.shade300 : Colors.cyan.shade800;
            break;
          default:
            icon = Icon(Icons.directions_walk);
            showText = false;
        }
        
        return Flexible(
          flex: math.max(legPercentages[index].round(), 1), // Ensure minimum flex of 1
          child: Container(
            height: 32,
            decoration: BoxDecoration(color: color),
            child: shouldShowIcon 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                    child: shouldShowTextContent 
                        // Show icon + text in a row
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon.icon,
                                color: onColor,
                                size: 16
                              ),
                              Flexible(child: Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(text, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: onColor, fontWeight: FontWeight.bold) , overflow: TextOverflow.ellipsis,),
                              ))
                            ],
                          )
                        // Show only icon, centered
                        : Icon(
                            icon.icon,
                            color: onColor,
                            size: 16
                          ),
                  ),
                )
              : Container(), // Empty container if segment is too small
          ),
        );
      }),
    );
  
  }));
}


  int? getShortestInterchange(Journey journey) {
  if (journey.legs.isEmpty) {
    return null;
  }



  List<int> interchangeTimes = [];
  List<int> transitLegIndices = [];

  // First, identify which legs are actual transit (not walking, not same-station)
  for (int index = 0; index < journey.legs.length; index++) {
    final leg = journey.legs[index];

    // Skip walking legs
    if (leg.isWalking == true) continue;

    // Skip legs that are same-station interchanges (same origin and destination)
    bool isSameStationInterchange =
        leg.origin.id == leg.destination.id &&
        leg.origin.name == leg.destination.name;

    if (!isSameStationInterchange) {
      transitLegIndices.add(index);
    }
  }

  // Check for interchanges between consecutive transit legs
  for (int i = 1; i < transitLegIndices.length; i++) {
    final currentLegIndex = transitLegIndices[i];
    final currentLeg = journey.legs[currentLegIndex];
    final previousLegIndex = transitLegIndices[i - 1];
    final previousLeg = journey.legs[previousLegIndex];

    bool shouldCalculateInterchange = false;
    Leg arrivingLeg = previousLeg;
    Leg departingLeg = currentLeg;

    // Case 1: Different lines at the same station
    if (previousLeg.destination.id == currentLeg.origin.id &&
        previousLeg.destination.name == currentLeg.origin.name &&
        previousLeg.lineName != currentLeg.lineName) {
      shouldCalculateInterchange = true;
    }
    
    // Case 2: Same station complex (using RIL100 IDs) but different lines
    else if (previousLeg.destination.ril100Ids.isNotEmpty &&
             currentLeg.origin.ril100Ids.isNotEmpty &&
             _haveSameRil100ID(
               previousLeg.destination.ril100Ids,
               currentLeg.origin.ril100Ids,
             ) &&
             previousLeg.lineName != currentLeg.lineName) {
      shouldCalculateInterchange = true;
    }
    
    // Case 3: There are intermediate legs (like same-station interchanges) between transit legs
    else if (currentLegIndex - previousLegIndex > 1) {
      // Check if there's a same-station interchange or walking connection between them
      for (int interchangeIndex = previousLegIndex + 1;
           interchangeIndex < currentLegIndex;
           interchangeIndex++) {
        final interchangeLeg = journey.legs[interchangeIndex];

        // If this is a same-station interchange or connects the two transit legs
        if ((interchangeLeg.origin.id == interchangeLeg.destination.id &&
             interchangeLeg.origin.name == interchangeLeg.destination.name) ||
            (interchangeLeg.origin.id == previousLeg.destination.id &&
             interchangeLeg.destination.id == currentLeg.origin.id)) {
          shouldCalculateInterchange = true;
          break;
        }
      }
    }

    // Calculate interchange time if we should
    if (shouldCalculateInterchange) {
      try {
        final arrivalTime = arrivingLeg.arrivalDateTime;
        final departureTime = departingLeg.departureDateTime;
        final interchangeMinutes = departureTime.difference(arrivalTime).inMinutes;
        
        // Only consider positive interchange times (sanity check)
        if (interchangeMinutes > 0) {
          interchangeTimes.add(interchangeMinutes);
        }
      } catch (e) {
        // Skip this interchange if we can't parse the times
        print('Error calculating interchange time: $e');
        continue;
      }
    }
  }

  // Return the shortest interchange time, or null if no interchanges found
  if (interchangeTimes.isEmpty) {
    return null;
  }

  return interchangeTimes.reduce((a, b) => a < b ? a : b);
}

  
  

  int calculateTotalInterchanges(Journey journey) {
  if (journey.legs.isEmpty) {
    return 0;
  }

  int interchangeCount = 0;
  List<int> transitLegIndices = [];

  // First, identify which legs are actual transit (non-walking) vs same-station interchanges
  for (int index = 0; index < journey.legs.length; index++) {
    final leg = journey.legs[index];

    // Skip legs that are same-station interchanges (same origin and destination)
    bool isSameStationInterchange =
        leg.origin.id == leg.destination.id &&
        leg.origin.name == leg.destination.name;

    // Skip walking legs and only include actual transit modes
    bool isTransitLeg = !isSameStationInterchange && leg.isWalking != true;

    if (isTransitLeg) {
      transitLegIndices.add(index);
    }
  }

  // Count interchanges between transit legs only
  for (int i = 1; i < transitLegIndices.length; i++) {
    final legIndex = transitLegIndices[i];
    final leg = journey.legs[legIndex];
    final previousLegIndex = transitLegIndices[i - 1];
    final previousLeg = journey.legs[previousLegIndex];

    // Since we're only looking at transit legs, any transition between them
    // represents a real interchange between different transport modes
    bool shouldCountInterchange = false;

    // Case 1: There are legs between previous and current that represent interchanges
    if (legIndex - previousLegIndex > 1) {
      // There are intermediate legs (likely walking or same-station transfers)
      // This indicates an interchange between different transit modes
      shouldCountInterchange = true;
    }
    // Case 2: Direct connection between different transit modes
    else if (previousLeg.destination.id == leg.origin.id &&
        previousLeg.destination.name == leg.origin.name &&
        previousLeg.lineName != leg.lineName) {
      // Different lines at the same station = interchange
      shouldCountInterchange = true;
    }
    // Case 3: Different stations but within same station complex
    else if (previousLeg.destination.ril100Ids.isNotEmpty &&
        leg.origin.ril100Ids.isNotEmpty &&
        _haveSameRil100ID(
          previousLeg.destination.ril100Ids,
          leg.origin.ril100Ids,
        )) {
      // Within same station complex but different transit modes = interchange
      shouldCountInterchange = true;
    }
    // Case 4: Completely different stations
    else if (previousLeg.destination.id != leg.origin.id ||
        previousLeg.destination.name != leg.origin.name) {
      // Different stations = interchange (with walking in between)
      shouldCountInterchange = true;
    }

    // Increment counter if interchange should be counted
    if (shouldCountInterchange) {
      interchangeCount++;
    }
  }

  return interchangeCount;
}

  bool _haveSameRil100ID(
    List<String> ril100Ids1,
    List<String> ril100Ids2,
  ) {
    if (ril100Ids1.isEmpty || ril100Ids2.isEmpty) {
      return false;
    }

    // Check if any RIL100 ID from the first list matches any from the second list
    for (String id1 in ril100Ids1) {
      for (String id2 in ril100Ids2) {
        if (id1 == id2) {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.departure_board),
                label: Text(_selectedTime.format(context)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                    helpText: 'Select Departure or Arrival Time',
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          timePickerTheme: TimePickerThemeData(
                            helpTextStyle: TextStyle(
                              color:
                                  colors.onSurface, // Use a high-contrast color
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.calendar_month),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _selectedDate,
                    helpText: 'Select Departure Or Arrival Date',
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                label: Text(
                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                ),
              ),
            ),
            // Reset button
            IconButton.filledTonal(
              onPressed: () {
                setState(() {
                  _selectedTime = TimeOfDay.now();
                  _selectedDate = DateTime.now();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reset to current date and time'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.refresh),
              tooltip: 'Reset to now',
            ),
            IconButton.filledTonal(
              onPressed: () async {
                final updatedSettings = await showDialog<JourneySettings>(
                  context: context,
                  builder: (BuildContext context) {
                    // Make a local copy so changes don't affect original until "Apply"
                    JourneySettings tempSettings = JourneySettings(
                      national: journeySettings.national,
                      nationalExpress: journeySettings.nationalExpress,
                      regional: journeySettings.regional,
                      regionalExpress: journeySettings.regionalExpress,
                      suburban: journeySettings.suburban,
                      subway: journeySettings.subway,
                      tram: journeySettings.tram,
                      bus: journeySettings.bus,
                      ferry: journeySettings.ferry,
                      deutschlandTicketConnectionsOnly:
                          journeySettings.deutschlandTicketConnectionsOnly,
                      accessibility: journeySettings.accessibility,
                      walkingSpeed: journeySettings.walkingSpeed,
                      transferTime: journeySettings.transferTime,
                    );

                    return AlertDialog(
                      title: Text(
                        'Journey Preferences',
                        style: TextStyle(color: colors.onSurface),
                      ),
                      content: Flexible(
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'Modes of Transport',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include ICE',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.national ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.national = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include IC/EC',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.nationalExpress ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.nationalExpress = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include RE/RB',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.regional ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.regional = value;
                                        tempSettings.regionalExpress = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include S-Bahn',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.suburban ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.suburban = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include U-Bahn',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.subway ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.subway = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include Tram',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.tram ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.tram = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include Bus',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.bus ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.bus = value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Include Ferry',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.ferry ?? true,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.ferry = value;
                                      });
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'Journey Settings',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Deutschlandticket only',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value:
                                        tempSettings
                                            .deutschlandTicketConnectionsOnly ??
                                        false,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings
                                                .deutschlandTicketConnectionsOnly =
                                            value;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      'Accessibility',
                                      style: TextStyle(color: colors.onSurface),
                                    ),
                                    value: tempSettings.accessibility ?? false,
                                    onChanged: (value) {
                                      setState(() {
                                        tempSettings.accessibility = value;
                                      });
                                    },
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Walking Speed',
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                                  initialValue:
                                                      tempSettings.walkingSpeed ??
                                                      'normal',
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                  ),
                                                  style: TextStyle(
                                                    color: colors.onSurface,
                                                  ),
                                                  iconEnabledColor:
                                                      colors.primary,
                                                  items: [
                                                    DropdownMenuItem(
                                                      value: 'slow',
                                                      child: Text('Slow'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'normal',
                                                      child: Text('Normal'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'fast',
                                                      child: Text('Fast'),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      tempSettings.walkingSpeed =
                                                          value;
                                                    });
                                                  },
                                                ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Text(
                                            'Transfer Time',
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: DropdownButtonFormField<int?>(
                                              initialValue: tempSettings.transferTime,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                color: colors.onSurface,
                                              ),
                                              iconEnabledColor: colors.primary,
                                              items: [
                                                DropdownMenuItem(
                                                  value: null,
                                                  child: Text('Default (None)'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 5,
                                                  child: Text('Min. 5 Minutes'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 15,
                                                  child: Text('Min. 15 Minutes'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 30,
                                                  child: Text('Min. 30 Minutes'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  tempSettings.transferTime =
                                                      value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(), // Cancel
                          child: Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(tempSettings); // Return updated settings
                          },
                          child: Text('Apply'),
                        ),
                      ],
                    );
                  },
                );

                // If user pressed Apply and returned settings, update state
                if (updatedSettings != null) {
                  setState(() {
                    journeySettings = updatedSettings;
                  });
                }
              },
              icon: Icon(Icons.settings),
              tooltip: 'Journey Settings',
            ),
          ],
        ),

        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(value: true, label: Text('Departure')),

                  ButtonSegment<bool>(value: false, label: Text('Arrival')),
                ],

                selected: {departure},

                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    departure = newSelection.first;
                  });
                },
              ),
            ),
            GestureDetector(
              onTap: _search,
              child: AnimatedContainer(
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(inJourneySearchAnimation ? 8 : 24),
                  color: inJourneySearchAnimation ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primaryContainer
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedRotation(
                        curve: Curves.easeInOut,
                        turns: rotatingSearchIconTurns, 
                        duration: Duration(milliseconds: 600),
                        onEnd: () {
                          setState(() {
                            if(inJourneySearchAnimation)
                            {
                                rotatingSearchIconTurns++;
                            }
                          });
                        },
                        child: Icon(Icons.search, color: inJourneySearchAnimation ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer, size: 16)
                        ),
                        SizedBox(width: 8),
                        Text('Search', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: inJourneySearchAnimation ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer))
                        
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget buildFavouriteButton(BuildContext context, Location location){

    bool alreadyFave = false;
    FavoriteLocation? thatFave;
    for(int i = 0; i < faves.length; i++)
    {
      if(faves[i].location.id == location.id)
      {
        print(location.id);
        print(faves[i].location.id);
        alreadyFave = true;
        thatFave = faves[i];
      }
    }

    if(alreadyFave)
    {
      return IconButton(
                icon: Icon(Icons.favorite),
                onPressed: () => 
                {
                  setState(() {
                    faves.remove(thatFave);
                    Localdatasaver.removeFavouriteLocation(thatFave!);
                  })
                });
    }

    
    return IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: () => showDialog(context: context, builder: (BuildContext context)
                {
                  TextEditingController c = TextEditingController();
                  return AlertDialog(
                    title: Text('Save Location', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface),),
                    content: 
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Give the location a name so you can better remember it', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                        TextField(controller: c, style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),),
                      ],
                      
                    ),
                    actions: [
                      TextButton(onPressed: () {Navigator.of(context).pop();}, child: Text('Cancel')),
                      TextButton(onPressed: () async {
                        Localdatasaver.addLocationToFavourites(location, c.text); 
                        List<FavoriteLocation> updatedFaves = await Localdatasaver.getFavouriteLocations();
                        setState(() {
                          faves = updatedFaves;
                        });
                        Navigator.of(context).pop();
                        }, 
                        child: Text('Save'))
                    ],
                  );
                })
              );
  }

  void _search() async {
    setState(() {
      inJourneySearchAnimation = true;
      rotatingSearchIconTurns++;
    });
    try {
      // Debug prints
      print('From: ${widget.page.from}');
      print('To: ${widget.page.to}');
      searching = false;

      await getJourneys(
        widget.page.from.id,
        widget.page.to.id,
        widget.page.from.latitude,
        widget.page.from.longitude,
        widget.page.to.latitude,
        widget.page.to.longitude,
        DateAndTime.fromDateTimeAndTime(_selectedDate, _selectedTime),
        departure,
      );
    } catch (e) {
      print('Error in search: $e');
      setState(() {
        _currentJourneys = [];
        inJourneySearchAnimation = false;
         // Set to empty list to show "no results"
      });
    }
  }
}
