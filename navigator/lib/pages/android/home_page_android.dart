import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/pages/android/connections_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/models/station.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/services/localDataSaver.dart';

class HomePageAndroid extends StatefulWidget {
  final HomePage page;
  final bool ongoingJourney;

  const HomePageAndroid(this.page, this.ongoingJourney, {Key? key})
    : super(key: key);

  @override
  State<HomePageAndroid> createState() => _HomePageAndroidState();
}

class _HomePageAndroidState extends State<HomePageAndroid>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<Location> _searchResults = [];
  String _lastSearchedText = '';
  Timer? _debounce;
  LatLng? _currentUserLocation;
  LatLng _currentCenter = LatLng(52.513416, 13.412364);
  double _currentZoom = 10;
  final MapController _mapController = MapController();
  List<Polyline> _lines = [];
  List<Station> _stations = [];
  bool showStationLabels = true;

  //Map Options
  bool showLightRail = true;
  List<Polyline> _lightRailLines = [];
  bool showSubway = true;
  List<Polyline> _subwayLines = [];
  bool showTram = false;
  List<Polyline> _tramLines = [];
  // bool showBus = false;
  // List<Polyline> _busLines = [];
  // bool showTrolleybus = false;
  // List<Polyline> _trolleyBusLines = [];
  bool showFerry = false;
  List<Polyline> _ferryLines = [];
  bool showFunicular = false;
  List<Polyline> _funicularLines = [];
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  List<FavoriteLocation> faves = [];

  @override
  void initState() {
    super.initState();
    initiateLines();
    fetchStations();

    _alignPositionOnUpdate = AlignOnUpdate.always;
    _alignPositionStreamController = StreamController<double?>();

    _controller.addListener(() {
      _onSearchChanged(_controller.text.trim());
    });

    _setInitialUserLocation();
    _getFaves();
  }

  Future<void> _getFaves() async
  {
    List<FavoriteLocation> f = await Localdatasaver.getFavouriteLocations();
    setState(() {
      faves = f;
    });
  }

  Future<void> initiateLines() async {
    await widget.page.service.refreshPolylines();

    print(
      "loadedSubwayLines.length = ${widget.page.service.loadedSubwayLines.length}",
    );
    print(
      "First line length: ${widget.page.service.loadedSubwayLines.firstOrNull?.points.length ?? 0}",
    );

    if (widget.page.service.loadedSubwayLines.isNotEmpty) {
      setState(() {
        _lines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty,
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60)
                // Use the actual line color!
              ),
            )
            .toList();
            _subwayLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'subway',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60)
                // Use the actual line color!
              ),
            )
            .toList();
            _lightRailLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'light_rail',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60)
                // Use the actual line color!
              ),
            )
            .toList();
            _tramLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'tram',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60)
                // Use the actual line color!
              ),
            )
            .toList();
            // _busLines = widget.page.service.loadedSubwayLines
            // .where(
            //   (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'bus',
            // ) // prevent empty lines
            // .map(
            //   (subwayLine) => Polyline(
            //     points: subwayLine.points,
            //     strokeWidth: 1.0,
            //     color: subwayLine.color,
            //     borderColor: subwayLine.color.withAlpha(60)
            //     // Use the actual line color!
            //   ),
            // )
            // .toList();
            // _trolleyBusLines = widget.page.service.loadedSubwayLines
            // .where(
            //   (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'trolleybus',
            // ) // prevent empty lines
            // .map(
            //   (subwayLine) => Polyline(
            //     points: subwayLine.points,
            //     strokeWidth: 1.0,
            //     color: subwayLine.color,
            //     borderColor: subwayLine.color.withAlpha(60)
            //     // Use the actual line color!
            //   ),
            // )
            // .toList();
            _ferryLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'ferry',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 1.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60)
                // Use the actual line color!
              ),
            )
            .toList();
            _funicularLines = widget.page.service.loadedSubwayLines
            .where(
              (subwayLine) => subwayLine.points.isNotEmpty && subwayLine.type == 'funicular',
            ) // prevent empty lines
            .map(
              (subwayLine) => Polyline(
                points: subwayLine.points,
                strokeWidth: 2.0,
                color: subwayLine.color,
                borderColor: subwayLine.color.withAlpha(60)
                // Use the actual line color!
              ),
            )
            .toList();
      });

      print("Mapped ${_lines.length} colored polylines for display.");

      // Debug: Print some color info
      for (var line in widget.page.service.loadedSubwayLines.take(3)) {
        print("Line: ${line.lineName} - Color: ${line.color}");
      }
    }
  }

  Future<void> fetchStations() async {
    final location = await widget.page.service.getCurrentLocation();

    if (location.latitude != 0 && location.longitude != 0) {
      try {
        final transportTypes = ['subway', 'light_rail', 'tram'];
        final fetchedStations = await widget.page.service.overpass.fetchStationsByType(
          lat: location.latitude,
          lon: location.longitude,
          radius: 50000
        );

        setState(() {
          _stations = fetchedStations;
        });

        print("✅ Loaded ${_stations.length} station labels");
      } catch (e) {
        print('Error fetching stations: $e');
      }
    }
  }

  String _getLabelCollisionKey(Station station, double zoom) {
    // Adjust the grid size based on zoom level
    double gridSize = 100; // pixels

    if (zoom > 16.5) {
      gridSize = 150;
    } else if (zoom > 15.5) {
      gridSize = 120;
    }

    // Convert lat/lng to a rough grid position
    // This is a simplification that works for collision detection
    final gridX = (station.latitude * 1000 / gridSize).round();
    final gridY = (station.longitude * 1000 / gridSize).round();

    return "$gridX:$gridY";
  }

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _currentCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _currentCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: _currentZoom, end: destZoom);

    var controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _setInitialUserLocation() async {
    final loc = await widget.page.service.getCurrentLocation();

    if (loc.latitude != 0 && loc.longitude != 0) {
      final newCenter = LatLng(loc.latitude, loc.longitude);
      setState(() {
        _currentUserLocation = newCenter;
      });

      animatedMapMove(newCenter, 12.0);
      fetchStations();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query != _lastSearchedText) {
        getSearchResults(query);
        _lastSearchedText = query;
      }
    });
  }

  Future<void> getSearchResults(String query) async {
    final results = await widget.page.getLocations(query); // async method
    setState(() {
      _searchResults = results;
    });
  }

  IconData _getTransportIcon(Station station) {
    if (station.subway) return Icons.subway;
    if (station.tram) return Icons.tram;
    if (station.suburban) return Icons.directions_subway;
    if (station.national || station.nationalExpress) return Icons.train;
    if (station.regional || station.regionalExpress) return Icons.directions_railway;
    if (station.ferry) return Icons.directions_ferry;
    if (station.bus) return Icons.directions_bus;
    return Icons.location_on;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _alignPositionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasResults = _searchResults.isNotEmpty;
    const bottomSheetHeight = 96.0;

    return WillPopScope(
      onWillPop: () async {
        if (hasResults) {
          // clear the search and go back to the map
          setState(() {
            _searchResults.clear();
            _lastSearchedText = '';
            _controller.clear();
          });
          return false; // prevent actual pop
        }
        return true; // allow actual back navigation if no results
      },
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim)
          {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero
            ).animate(anim);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: hasResults
              ? SafeArea(
                  child: ListView.builder(
                    key: const ValueKey('list'),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      bottomSheetHeight + 16,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, i) {
                      final r = _searchResults[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: r is Station
                            ? _stationResult(context, r)
                            : _locationResult(context, r),
                      );
                    },
                  ),
                )
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentUserLocation ?? _currentCenter,
              initialZoom: _currentZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom | InteractiveFlag.rotate,
                rotationThreshold: 20.0,
                pinchZoomThreshold: 0.5,
                pinchMoveThreshold: 40.0,
              ),
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture && _alignPositionOnUpdate != AlignOnUpdate.never) {
                  setState(() => _alignPositionOnUpdate = AlignOnUpdate.never);
                }
                // Update current zoom level
                setState(() {
                  _currentZoom = camera.zoom;
                  _currentCenter = camera.center;
                });
              },
            ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    CurrentLocationLayer(
                      alignPositionStream: _alignPositionStreamController.stream,
                      alignPositionOnUpdate: _alignPositionOnUpdate,
                      style: LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          color: Colors.lightBlue[800]!,
                        ),
                        markerSize: const Size(20, 20),
                        markerDirection: MarkerDirection.heading,
                        accuracyCircleColor: Colors.blue[200]!.withAlpha(0x20),
                        headingSectorColor: Colors.blue[400]!.withAlpha(0x90),
                        headingSectorRadius: 60,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0, bottom: 160.0),
                        child: FloatingActionButton(
                          shape: const CircleBorder(),
                          onPressed: () {
                            // Align the location marker to the center of the map widget
                            // on location update until user interact with the map.
                            setState(
                                  () => _alignPositionOnUpdate = AlignOnUpdate.always,
                            );
                            // Align the location marker to the center of the map widget
                            // and zoom the map to level 18.
                            _alignPositionStreamController.add(18);
                          },
                          child: Icon(
                            Icons.my_location,
                            color: colors.tertiary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    if(showSubway)
                    PolylineLayer(polylines: _subwayLines),
                    if(showLightRail)
                    PolylineLayer(polylines: _lightRailLines),
                    if(showTram)
                    PolylineLayer(polylines: _tramLines),
                    // if(showBus)
                    // PolylineLayer(polylines: _busLines),
                    // if(showTrolleybus)
                    // PolylineLayer(polylines: _trolleyBusLines),
                    if(showFerry)
                    PolylineLayer(polylines: _ferryLines),
                    if(showFunicular)
                    PolylineLayer(polylines: _funicularLines),
                    if (showStationLabels && _currentZoom > 14) // Only show labels when zoomed in enough
                      MarkerLayer(
                        markers: _stations
                            .where((station) {
                          // Filter stations based on zoom level and type
                          if (_currentZoom < 11.5) return false; // Don't show any stations when zoomed far out

                          // Filter by transportation type settings
                          if ((station.subway && !showSubway) ||
                              (station.suburban && !showLightRail) ||
                              (station.tram && !showTram) ||
                              (station.ferry && !showFerry)) {
                            return false;
                          }

                          // At medium zoom (11.5-14), only show important stations
                          if (_currentZoom < 14) {
                            return station.subway || station.national ||
                                station.nationalExpress || station.suburban;
                          }

                          // At higher zoom levels, show all stations
                          return true;
                        })
                        // Group by name and take only the first station of each name when zoomed out
                            .fold<Map<String, Station>>({}, (map, station) {
                          if (_currentZoom <= 15.5 && !map.containsKey(station.name)) {
                            map[station.name] = station;
                          } else if (_currentZoom > 15.5) {
                            // When zoomed in, show all stations individually
                            map["${station.name}_${station.latitude}_${station.longitude}"] = station;
                          }
                          return map;
                        })
                            .values
                        // Apply collision detection for labels when zoomed in, but not at extreme zoom
                            .fold<Map<String, List<Station>>>({}, (collisionMap, station) {
                          if (_currentZoom > 16.5) {
                            // At very high zoom levels, bypass collision detection completely
                            // Each station gets its own unique key to ensure all are shown
                            final uniqueKey = "${station.name}_${station.latitude}_${station.longitude}";
                            collisionMap[uniqueKey] = [station];
                          } else {
                            // Normal collision detection at moderate zoom levels
                            final key = _getLabelCollisionKey(station, _currentZoom);
                            if (!collisionMap.containsKey(key)) {
                              collisionMap[key] = [];
                            }
                            collisionMap[key]!.add(station);
                          }
                          return collisionMap;
                        })
                            .entries
                            .expand((entry) {
                          final stations = entry.value;
                          // If multiple stations share the same collision key, only keep one instance of each name
                          // but only apply this logic at lower zoom levels
                          if (stations.length > 1 && _currentZoom <= 17) {
                            final uniqueByName = <String, Station>{};
                            for (final station in stations) {
                              uniqueByName[station.name] = station;
                            }
                            return uniqueByName.values;
                          }
                          return stations;
                        })
                            .map((station) {
                          return Marker(
                            point: LatLng(station.latitude, station.longitude),
                            width: 150,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Only show the label text when zoomed in close enough
                                if (_currentZoom > 15.5)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      station.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (_currentZoom > 14.5)
                                  const SizedBox(height: 2),
                                Container(
                                  decoration: BoxDecoration(
                                    // Scale marker size based on zoom level
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(_currentZoom > 14 ? 4 : 3),
                                  child: Icon(
                                    _getTransportIcon(station),
                                    color: colors.onPrimary,
                                    size: _currentZoom > 14 ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
        bottomSheet: Material(
          color: colors.surfaceContainer,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onSearchChanged,
                        style: TextStyle(color: colors.onPrimaryContainer),
                        decoration: InputDecoration(
                          hintText: 'Where do you want to go?',
                          prefixIcon: Icon(Icons.location_pin, color: colors.primary),
                          filled: true,
                          fillColor: colors.primaryContainer,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.4, // 40% of screen
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: <Widget>[
                        // Handle bar
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Map Options',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              CheckboxListTile(
                                title: const Text('Show Station Labels'),
                                value: showStationLabels,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    showStationLabels = value!;
                                  });
                                  setState(() {
                                    showStationLabels = value!;
                                  });
                                },
                              ),
                              CheckboxListTile(
                                    title: const Text('Show S-Bahn'),
                                    value: showLightRail,
                                    onChanged: (bool? value) {
                                      setModalState(() {
                                        showLightRail = value!;
                                      });
                                      setState(() {
                                        showLightRail = value!;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Show U-Bahn'),
                                    value: showSubway,
                                    onChanged: (bool? value) {
                                      setModalState(() {
                                        showSubway = value!;
                                      });
                                      setState(() {
                                        showSubway = value!;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Show Tram'),
                                    value: showTram,
                                    onChanged: (bool? value) {
                                      setModalState(() {
                                        showTram = value!;
                                      });
                                      setState(() {
                                        showTram = value!;
                                      });
                                    },
                                  ),
                                  // CheckboxListTile(
                                  //   title: const Text('Show Bus'),
                                  //   value: showBus,
                                  //   onChanged: (bool? value) {
                                  //     setModalState(() {
                                  //       showBus = value!;
                                  //     });
                                  //     setState(() {
                                  //       showBus = value!;
                                  //     });
                                  //   },
                                  // ),
                                  // CheckboxListTile(
                                  //   title: const Text('Show Trolleybus'),
                                  //   value: showTrolleybus,
                                  //   onChanged: (bool? value) {
                                  //     setModalState(() {
                                  //       showTrolleybus = value!;
                                  //     });
                                  //     setState(() {
                                  //       showTrolleybus = value!;
                                  //     });
                                  //   },
                                  // ),
                                  CheckboxListTile(
                                    title: const Text('Show Ferry'),
                                    value: showFerry,
                                    onChanged: (bool? value) {
                                      setModalState(() {
                                        showFerry = value!;
                                      });
                                      setState(() {
                                        showFerry = value!;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Show Funicular'),
                                    value: showFunicular,
                                    onChanged: (bool? value) {
                                      setModalState(() {
                                        showFunicular = value!;
                                      });
                                      setState(() {
                                        showFunicular = value!;
                                      });
                                    },
                                  ),
                
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                          },
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.settings),
                )
                   ],
                ),
                SizedBox(height: 8),
                _buildFaves(context),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
          ],
        ),
      ),
    );
  }

  Widget _buildFaves(BuildContext context) {
  return Row(
    children: [
      if(faves.isEmpty)
      Icon(Icons.favorite),
      if(faves.isEmpty)
      SizedBox(width: 16,),
      if(faves.isEmpty)
        Text('No saved Locations so far'),
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
                    disabledColor: Theme.of(context).colorScheme.tertiaryContainer,
                    onPressed: () => {Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionsPageAndroid(
                ConnectionsPage(
                  from: Location(
                    id: '',
                    latitude: 0,
                    longitude: 0,
                    name: '',
                    type: '',
                  ),
                  to: f.location,
                  services: widget.page.service,
                ),
              ),
            ),
          )},
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
    ],
  );
}


  Widget _stationResult(BuildContext context, Station station) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionsPageAndroid(
                ConnectionsPage(
                  from: Location(
                    id: '',
                    latitude: 0,
                    longitude: 0,
                    name: '',
                    type: '',
                  ),
                  to: station,
                  services: widget.page.service,
                ),
              ),
            ),
          );
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
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionsPageAndroid(
                ConnectionsPage(
                  from: Location(
                    id: '',
                    latitude: 0,
                    longitude: 0,
                    name: '',
                    type: '',
                  ),
                  to: location,
                  services: widget.page.service,
                ),
              ),
            ),
          );
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

              IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: () => showDialog(context: context, builder: (BuildContext context)
                {
                  TextEditingController c = new TextEditingController();
                  return AlertDialog(
                    title: Text('Save Location'),
                    content: 
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Give the location a name so you can better remember it'),
                        TextField(controller: c),
                      ],
                      
                    ),
                    actions: [
                      TextButton(onPressed: () {Navigator.of(context).pop();}, child: Text('Cancel')),
                      TextButton(onPressed: () {Localdatasaver.addLocationToFavourites(location, c.text); Navigator.of(context).pop();}, child: Text('Save'))
                    ],
                  );
                })
              ),

              // Chevron affordance
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}