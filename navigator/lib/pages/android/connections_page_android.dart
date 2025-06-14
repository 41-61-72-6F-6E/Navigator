import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/pages/page_models/journey_page.dart';

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
  late Position _selectedPosition;
  late List<Journey> _currentJourneys;
  late List<Location> _searchResultsFrom;
  late List<Location> _searchResultsTo;
  String _lastSearchedText = '';
  Timer? _debounce;
  late FocusNode _fromFocusNode;
  late FocusNode _toFocusNode;
  bool departure = true;
  bool searching = false;
  bool searchingFrom = true;

  @override
  void initState() {
    super.initState();
    //Initializers
    updateLocationWithCurrentPosition(widget.page.from);
    _fromFocusNode = FocusNode();
    _toFocusNode = FocusNode();
    _toController = TextEditingController(text: widget.page.to?.name);
    _fromController = TextEditingController();
    _selectedTime = TimeOfDay.now();
    _selectedDate = DateTime.now();

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

  String _buildAddressString(String city, String street) {
    final safeCity = city.trim();
    final safeStreet = street.trim();

    if (safeCity.isNotEmpty && safeStreet.isNotEmpty) {
      return '$safeCity, $safeStreet';
    } else if (safeCity.isNotEmpty) {
      return safeCity;
    } else if (safeStreet.isNotEmpty) {
      return safeStreet;
    } else {
      return '';
    }
  }

  //async to Sync functions
  Future<void> updateLocationWithCurrentPosition(Location l) async {
    l = await widget.page.services.getCurrentLocation();
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
    String? fromAddress;
    if (fromId.isEmpty) {
      try {
        final placemarks = await geo.placemarkFromCoordinates(fromLat, fromLon);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final city = placemark.locality ?? '';
          final street = placemark.street ?? '';
          fromAddress = _buildAddressString(city, street);
        }
      } catch (e) {
        print('Failed to get address for from coordinates: $e');
        fromAddress = null;
      }
    }

    String? toAddress;
    if (toId.isEmpty) {
      try {
        final placemarks = await geo.placemarkFromCoordinates(toLat, toLong);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final city = placemark.locality ?? '';
          final street = placemark.street ?? '';
          toAddress = _buildAddressString(city, street);
        }
      } catch (e) {
        print('Failed to get address for to coordinates: $e');
        toAddress = null;
      }
    }

    // Rest of the method remains the same...
    final from = fromId.isEmpty
        ? Location(
            id: '',
            latitude: fromLat,
            longitude: fromLon,
            name: "Current Location",
            type: "geo",
            address: fromAddress,
          )
        : Location(
            id: fromId,
            latitude: 0,
            longitude: 0,
            name: "",
            type: "",
            address: null,
          );

    final to = toId.isEmpty
        ? Location(
            id: '',
            latitude: toLat,
            longitude: toLong,
            name: widget.page.to.name,
            type: widget.page.to.type,
            address: toAddress,
          )
        : Location(
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
    );

    setState(() {
      _currentJourneys = journeys;
    });
  }

  Future<void> _fetchJourneysFromCurrentLocation() async {
    if (_selectedPosition == null) return;

    final now = DateTime.now();
    final tzOffset = now.timeZoneOffset;

    final when = DateAndTime(
      day: _selectedDate.day,
      month: _selectedDate.month,
      year: _selectedDate.year,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      timeZoneHourShift: tzOffset.inHours,
      timeZoneMinuteShift: tzOffset.inMinutes % 60,
    );

    String? fromAddress;
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        _selectedPosition!.latitude,
        _selectedPosition!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = placemark.locality ?? '';
        final street = placemark.street ?? '';
        fromAddress = _buildAddressString(city, street);
      }
    } catch (e) {
      print('Failed to get address for current location: $e');
      fromAddress = null;
    }

    final from = Location(
      id: '',
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      name: 'Current Location',
      type: 'geo',
      address: fromAddress,
    );

    final to = Location(
      id: widget.page.to.id,
      latitude: widget.page.to.latitude,
      longitude: widget.page.to.longitude,
      name: widget.page.to.name,
      type: widget.page.to.type,
      address: null,
    );

    final journeys = await widget.page.services.getJourneys(
      from,
      to,
      when,
      departure,
    );

    setState(() {
      _currentJourneys = journeys;
    });
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
              //Search related Buttons
              _buildButtons(context),

              //Results
              if (searching) _buildSearchResults(context, searchingFrom),

              if (!searching) _buildJourneys(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
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
            } else {
              widget.page.to = station;
              _toController.text = station.name;
            }
          });
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
            } else {
              widget.page.to = location;
              _toController.text = location.name;
            }
          });
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
    return Column(
      children: [
        ElevatedButton(
          child: Text('Debug to get to journeys page'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  JourneyPageAndroid(JourneyPage(journey: Journey(legs: []))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
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
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                    helpText: 'Select Departure or Arrival Time',
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
                    initialDate: _selectedDate ?? DateTime.now(),
                    helpText: 'Select Departure Or Arrival Date',
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                label: Text(
                  _selectedDate.day.toString() +
                      '.' +
                      _selectedDate.month.toString() +
                      '.' +
                      _selectedDate.year.toString(),
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => {},
              icon: Icon(Icons.settings),
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
              onPressed: _fetchJourneysFromCurrentLocation,
              label: Text('Search'),
              icon: Icon(Icons.search),
            ),
          ],
        ),
      ],
    );
  }
}
