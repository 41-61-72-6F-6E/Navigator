import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/pages/page_models/journey_page.dart';

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
    updateLocationWithCurrentPosition(true);
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
  Future<void> updateLocationWithCurrentPosition(bool from) async {
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
      });
    } catch (e) {
      print('Error getting journeys: $e');
      setState(() {
        _currentJourneys = []; // Empty list to show "no results"
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
              _buildButtons(context),

              //Results
              if (searching)
                Expanded(child: _buildSearchResults(context, searchingFrom)),

              if (!searching) _buildJourneys(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: colors.surfaceContainerHighest,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }

  Widget _buildInputFields(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
        color: Theme.of(context).colorScheme.secondaryContainer,
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
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                      labelText: 'From',
                      prefixIcon: GestureDetector(
                        onTap: () async {
                          // Unfocus the text field first
                          _fromFocusNode.unfocus();

                          // Get current location and update the from field
                          await updateLocationWithCurrentPosition(true);

                          // Update the controller and state
                          _fromController.text =
                              "Current Location"; // This should probably be widget.page.from.name
                          // Don't set widget.page.from = widget.page.from (redundant)
                        },
                        child: Icon(Icons.location_on),
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
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                      labelText: 'To',
                      prefixIcon: GestureDetector(
                        onTap: () async {
                          // Unfocus the text field first
                          _toFocusNode.unfocus();

                          // Get current location and update the to field
                          await updateLocationWithCurrentPosition(false);

                          // Update the controller and state - FIX: use correct field
                          _toController.text =
                              "Current Location"; // This should probably be widget.page.to.name
                          //widget.page.to = widget.page.from; // This should probably be widget.page.to = currentLocation
                        },
                        child: Icon(Icons.location_on),
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
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                    iconSize: 32,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  onPressed: () {
                    print(widget.page.from.name);
                    print(widget.page.to.name);
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

              // Trailing chevron
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
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

              // Chevron affordance
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, bool searchingFrom) {
    if (searchingFrom) {
      if (_searchResultsFrom.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      return ListView.builder(
        key: const ValueKey('list'),
        padding: const EdgeInsets.all(8),
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
        padding: const EdgeInsets.all(8),
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
      return Center(child: CircularProgressIndicator());
    }
    if (_currentJourneys!.isEmpty) {
      return Center(child: Text('No journeys found'));
    }
    return Expanded(
      child: ListView.builder(
        key: const ValueKey('list'),
        padding: EdgeInsets.all(8),
        itemCount: _currentJourneys!.length,
        itemBuilder: (context, i) {
          final r = _currentJourneys![i];
          return Card(
            clipBehavior: Clip.hardEdge,
            shadowColor: Colors.transparent,
            color: Theme.of(context).colorScheme.secondaryContainer,
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
                        Text('Refreshing journey information...'),
                      ],
                    ),
                  ),
                );

                try {
                  // Refresh the journey using the service
                  final refreshedJourney = await widget.page.services
                      .refreshJourney(r);

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
                        JourneyPage(journey: r),
                        journey: r,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Planned Departure Time
                            Text(
                              '${r.legs[0].plannedDepartureDateTime?.hour.toString().padLeft(2, '0')}:${r.legs[0].plannedDepartureDateTime?.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            // Actual Departure Time
                            Text(
                              '${r.legs[0].departureDateTime?.hour.toString().padLeft(2, '0')}:${r.legs[0].departureDateTime?.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.labelSmall!
                                  .copyWith(
                                    color:
                                        r.legs[0].departureDateTime !=
                                            r.legs[0].plannedDepartureDateTime
                                        ? Colors.redAccent[400]
                                        : Theme.of(
                                            context,
                                          ).textTheme.labelSmall!.color,
                                  ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Planned Arrival Time
                            Text(
                              '${r.legs.last.plannedArrivalDateTime.hour.toString().padLeft(2, '0')}:${r.legs.last.plannedArrivalDateTime.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            // Actual Arrival Time
                            Text(
                              '${r.legs.last.arrivalDateTime.hour.toString().padLeft(2, '0')}:${r.legs.last.arrivalDateTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    r.legs.last.arrivalDateTime !=
                                        r.legs.last.plannedArrivalDateTime
                                    ? Colors.redAccent[400]
                                    : Theme.of(
                                        context,
                                      ).textTheme.labelSmall!.color,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            // Planned Duration
                            Text(
                              r.legs.last.plannedArrivalDateTime
                                  .difference(
                                    r.legs[0].plannedDepartureDateTime,
                                  )
                                  .inMinutes
                                  .toString(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            // Actual Duration
                            Text(
                              r.legs.last.arrivalDateTime
                                  .difference(r.legs[0].departureDateTime)
                                  .inMinutes
                                  .toString(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(child: _buildModeLine(context, r)),
                        Row(
                          children: [
                            Text((r.legs.length - 2).toString()),
                            Icon(Icons.transfer_within_a_station),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Leave in: ${r.legs[0].departureDateTime.difference(DateTime.now()).inMinutes}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeLine(BuildContext context, Journey j) {
    return Text('test');
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
                        style: TextStyle(color: colors.primary),
                      ),
                      content: StatefulBuilder(
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                    style: TextStyle(color: colors.primary),
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
                                            color: colors.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                                value:
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
                                                  color: colors.primary,
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
                                            color: colors.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: DropdownButtonFormField<int?>(
                                            value: tempSettings.transferTime,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                            ),
                                            style: TextStyle(
                                              color: colors.primary,
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
            FilledButton.tonalIcon(
              onPressed: () => _search(),

              label: Text('Search'),
              icon: Icon(Icons.search),
            ),
          ],
        ),
      ],
    );
  }

  void _search() async {
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
        _currentJourneys = []; // Set to empty list to show "no results"
      });
    }
  }
}
