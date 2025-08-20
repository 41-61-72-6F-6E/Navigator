import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/android/shared_bottom_navigation_android.dart';
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
                          await updateLocationWithCurrentPosition(true);

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
                          await updateLocationWithCurrentPosition(false);

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
          return _buildJourneyCard(context, r);
          // return Card(
          //   clipBehavior: Clip.hardEdge,
          //   shadowColor: Colors.transparent,
          //   color: Theme.of(context).colorScheme.secondaryContainer,
          //   child: InkWell(
          //     onTap: () async {
          //       // Show loading indicator
          //       showDialog(
          //         context: context,
          //         barrierDismissible: false,
          //         builder: (context) => AlertDialog(
          //           content: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               CircularProgressIndicator(),
          //               SizedBox(height: 16),
          //               Text(
          //                 'Refreshing journey information...',
          //                 style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          //               ),
          //             ],
          //           ),
          //         ),
          //       );

          //       try {
          //         // Refresh the journey using the service
          //         final refreshedJourney = await widget.page.services
          //             .refreshJourney(r);

          //         // Close the loading dialog
          //         Navigator.pop(context);

          //         // Navigate to journey page with the refreshed journey
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => JourneyPageAndroid(
          //               JourneyPage(journey: refreshedJourney),
          //               journey: refreshedJourney,
          //             ),
          //           ),
          //         );
          //       } catch (e) {
          //         // Close the loading dialog
          //         Navigator.pop(context);

          //         // Show error message
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text(
          //               'Could not refresh journey: ${e.toString()}',
          //             ),
          //             backgroundColor: Theme.of(context).colorScheme.error,
          //           ),
          //         );

          //         // Navigate with the original journey as fallback
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => JourneyPageAndroid(
          //               JourneyPage(journey: r),
          //               journey: r,
          //             ),
          //           ),
          //         );
          //       }
          //     },
          //     child: Padding(
          //       padding: EdgeInsets.all(16),
          //       child: Column(
          //         children: [
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: [
          //               Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   // Planned Departure Time
          //                   Text(
          //                     '${r.legs[0].plannedDepartureDateTime?.hour.toString().padLeft(2, '0')}:${r.legs[0].plannedDepartureDateTime?.minute.toString().padLeft(2, '0')}',
          //                     style: Theme.of(context).textTheme.titleMedium,
          //                   ),
          //                   // Actual Departure Time
          //                   Text(
          //                     '${r.legs[0].departureDateTime?.hour.toString().padLeft(2, '0')}:${r.legs[0].departureDateTime?.minute.toString().padLeft(2, '0')}',
          //                     style: Theme.of(context).textTheme.labelSmall!
          //                         .copyWith(
          //                           color:
          //                               r.legs[0].departureDateTime !=
          //                                   r.legs[0].plannedDepartureDateTime
          //                               ? Theme.of(context).colorScheme.error
          //                               : Theme.of(
          //                                   context,
          //                                 ).textTheme.labelSmall!.color,
          //                         ),
          //                   ),
          //                 ],
          //               ),
          //               Icon(Icons.arrow_forward),
          //               Column(
          //                 crossAxisAlignment: CrossAxisAlignment.end,
          //                 children: [
          //                   // Planned Arrival Time
          //                   Text(
          //                     '${r.legs.last.plannedArrivalDateTime.hour.toString().padLeft(2, '0')}:${r.legs.last.plannedArrivalDateTime.minute.toString().padLeft(2, '0')}',
          //                     style: Theme.of(context).textTheme.titleMedium,
          //                   ),
          //                   // Actual Arrival Time
          //                   Text(
          //                     r.legs.last.arrivalDateTime != null
          //                         ? '${r.legs.last.arrivalDateTime.hour.toString().padLeft(2, '0')}:${r.legs.last.arrivalDateTime.minute.toString().padLeft(2, '0')}'
          //                         : '--:--',
          //                     style: TextStyle(
          //                       fontSize: 12,
          //                       color:
          //                           r.legs.last.arrivalDateTime !=
          //                               r.legs.last.plannedArrivalDateTime
          //                           ? Theme.of(context).colorScheme.error
          //                           : Theme.of(
          //                               context,
          //                             ).textTheme.labelSmall!.color,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               Column(
          //                 children: [
          //                   // Planned Duration
          //                   Text(
          //                     r.legs.last.plannedArrivalDateTime
          //                         .difference(
          //                           r.legs[0].plannedDepartureDateTime,
          //                         )
          //                         .inMinutes
          //                         .toString(),
          //                     style: Theme.of(context).textTheme.titleMedium,
          //                   ),
          //                   // Actual Duration
          //                   Text(
          //                     r.legs.last.arrivalDateTime
          //                         .difference(r.legs[0].departureDateTime)
          //                         .inMinutes
          //                         .toString(),
          //                   ),
          //                 ],
          //               ),
          //             ],
          //           ),

          //           Row(
          //             children: [
          //               Expanded(child: _buildModeLine(context, r)),
          //               Row(
          //                 children: [
          //                   Text((r.legs.length - 2).toString()),
          //                   Icon(Icons.transfer_within_a_station),
          //                 ],
          //               ),
          //             ],
          //           ),
          //           Row(
          //             children: [
          //               Text(
          //                 'Leave in: ${r.legs[0].departureDateTime.difference(DateTime.now()).inMinutes}',
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // );
        },
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, Journey j)
  {
    String tripDuration = '';
    Duration tripD = j.legs.last.plannedArrivalDateTime.difference(j.legs.first.plannedDepartureDateTime);
    if(tripD.inMinutes < 60)
    {
      tripDuration = '${tripD.inMinutes} m';
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
    String plannedArrivalTimeMinute ='${j.legs.last.plannedArrivalDateTime.toLocal().hour}'.padLeft(2, '0');
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
    
    if (l.product == null || l.product!.isEmpty) {
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
      
      legNames.add(l.product!);
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
        const double minWidthForIcon = 32.0; // Need at least 24px for icon
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
            color = light ? Colors.deepOrange.shade900 : Colors.deepOrange.shade300;
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
            color = light ? Colors.pink.shade900 : Colors.pink.shade300;
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
          flex: legPercentages[index].round(),
          child: Container(
            height: 32,
            decoration: BoxDecoration(color: color),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: shouldShowIcon 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon.icon,
                          color: onColor,
                          size: 16
                        ),
                        if(shouldShowTextContent)
                        Flexible(child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(text, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: onColor, fontWeight: FontWeight.bold) , overflow: TextOverflow.ellipsis,),
                        ))
                      ],
                    )
                  : null, // Show nothing if segment is too small
              ),
            ),
          ),
        );
      }),
    );
  
  }));
}

  int calculateTotalInterchanges(Journey journey) {
  if (journey.legs.isEmpty) {
    return 0;
  }

  int interchangeCount = 0;
  List<int> actualLegIndices = [];

  // First, identify which legs are actual travel vs same-station interchanges
  for (int index = 0; index < journey.legs.length; index++) {
    final leg = journey.legs[index];

    // Skip legs that are same-station interchanges (same origin and destination)
    bool isSameStationInterchange =
        leg.origin.id == leg.destination.id &&
        leg.origin.name == leg.destination.name;

    if (!isSameStationInterchange) {
      actualLegIndices.add(index);
    }
  }

  // Count interchanges between actual legs
  for (int i = 1; i < actualLegIndices.length; i++) {
    final legIndex = actualLegIndices[i];
    final leg = journey.legs[legIndex];
    final previousLegIndex = actualLegIndices[i - 1];
    final previousLeg = journey.legs[previousLegIndex];

    // Check if there's an interchange between this leg and the previous actual leg
    bool shouldCountInterchange = false;

    // Case 1: There are legs between previous and current that represent interchanges
    if (legIndex - previousLegIndex > 1) {
      // Find the interchange leg(s) between them
      for (int interchangeIndex = previousLegIndex + 1;
           interchangeIndex < legIndex;
           interchangeIndex++) {
        final interchangeLeg = journey.legs[interchangeIndex];

        // If this is a same-station interchange
        if (interchangeLeg.origin.id == interchangeLeg.destination.id &&
            interchangeLeg.origin.name == interchangeLeg.destination.name) {
          shouldCountInterchange = true;
          break;
        }
      }
    }
    // Case 2: Direct connection between different modes (e.g., walking to transit)
    else if (previousLeg.destination.id == leg.origin.id &&
        previousLeg.destination.name == leg.origin.name &&
        ((previousLeg.isWalking == true && leg.isWalking != true) ||
            (previousLeg.isWalking != true && leg.isWalking == true) ||
            (previousLeg.isWalking != true &&
                leg.isWalking != true &&
                previousLeg.lineName != leg.lineName))) {
      shouldCountInterchange = true;
    }

    // Check if we're in the same station complex - this affects interchange logic
    bool isWithinStationComplex =
        previousLeg.destination.ril100Ids.isNotEmpty &&
        leg.origin.ril100Ids.isNotEmpty &&
        _haveSameRil100ID(
          previousLeg.destination.ril100Ids,
          leg.origin.ril100Ids,
        );

    // Special handling: If we're in the same station complex, consolidate the interchange
    if (isWithinStationComplex) {
      // Look backwards to find the last non-walking leg that brought us to this station complex
      for (int searchIndex = previousLegIndex;
           searchIndex >= 0;
           searchIndex--) {
        final searchLeg = journey.legs[searchIndex];

        // If this leg's destination is in the same station complex and it's not a walking leg
        if (searchLeg.isWalking != true &&
            _haveSameRil100ID(
              searchLeg.destination.ril100Ids,
              leg.origin.ril100Ids,
            )) {
          // Only count interchange if the current leg is not walking (i.e., we're exiting the station complex)
          if (leg.isWalking != true) {
            shouldCountInterchange = true;
          } else {
            // This is a walking leg within the station complex, don't count interchange yet
            shouldCountInterchange = false;
          }
          break;
        }
      }
    }

    // Special case for walking legs leaving a station complex
    if (!shouldCountInterchange &&
        leg.isWalking == true &&
        leg.origin.ril100Ids.isNotEmpty &&
        (leg.destination.ril100Ids.isEmpty ||
         !_haveSameRil100ID(leg.origin.ril100Ids, leg.destination.ril100Ids))) {
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
