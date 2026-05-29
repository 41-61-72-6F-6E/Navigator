import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/UIComponents/editFavoritesModal/editFavoritesModal.dart';
import 'package:navigator/widgets/homePage/UIComponents/favesBar/favesBar.dart';
import 'package:navigator/widgets/homePage/UIComponents/markerLayer/homePageMarkerLayer.dart';
import 'package:navigator/widgets/homePage/UIComponents/mapOptionsModal/mapOptionsModal.dart';
import 'package:navigator/widgets/homePage/UIComponents/ongoingJourneyBanner/ongoingJourneyBanner.dart';
import 'package:navigator/widgets/homePage/UIComponents/searchResultsCard/searchResultsCard.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class HomePageView extends StatefulWidget {
  final HomePageModel model;
  final int design;

  const HomePageView({
    super.key,
    required this.model,
    required this.design,
  });

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);

    widget.model.initiateLines();
    widget.model.fetchStations();
    widget.model.setInitialUserLocation(this);
    widget.model.initializeOngoingJourney();
    widget.model.getFaves();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.model.updateBrightness(
      Theme.of(context).colorScheme.brightness == Brightness.dark,
    );
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.model.state;
    final colors = Theme.of(context).colorScheme;
    final hasResults = state.searchResults.isNotEmpty;
    const bottomSheetHeight = 96.0;

    return WillPopScope(
      onWillPop: () async {
        if (hasResults) {
          widget.model.clearSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(anim);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              child: hasResults
                  ? SafeArea(
                      child: ListView.builder(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, bottomSheetHeight + 16),
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, i) {
                          final r = state.searchResults[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: r is Station
                                ? StationResultCard(
                                    design: widget.design,
                                    model: widget.model,
                                    station: r,
                                  )
                                : LocationResultCard(
                                    design: widget.design,
                                    model: widget.model,
                                    location: r,
                                  ),
                          );
                        },
                      ),
                    )
                  : FlutterMap(
                      mapController: widget.model.mapController,
                      options: MapOptions(
                        initialCenter: state.currentUserLocation ??
                            state.currentCenter,
                        initialZoom: state.currentZoom,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.drag |
                              InteractiveFlag.flingAnimation |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom |
                              InteractiveFlag.rotate,
                          rotationThreshold: 20.0,
                          pinchZoomThreshold: 0.5,
                          pinchMoveThreshold: 40.0,
                        ),
                        onPositionChanged: widget.model.onPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (state.showSubway)
                          PolylineLayer(polylines: state.subwayLines),
                        if (state.showLightRail)
                          PolylineLayer(polylines: state.lightRailLines),
                        if (state.showTram)
                          PolylineLayer(polylines: state.tramLines),
                        if (state.showFerry)
                          PolylineLayer(polylines: state.ferryLines),
                        if (state.showFunicular)
                          PolylineLayer(polylines: state.funicularLines),
                        if (state.ongoingJourney != null &&
                            state.ongoingJourneyPolylines.isNotEmpty)
                          PolylineLayer(
                              polylines: state.ongoingJourneyPolylines),
                        CurrentLocationLayer(
                          alignPositionStream: widget
                              .model.alignPositionStreamController.stream,
                          alignPositionOnUpdate: state.alignPositionOnUpdate,
                          style: LocationMarkerStyle(
                            marker: DefaultLocationMarker(
                                color: Colors.lightBlue[800]!),
                            markerSize: const Size(20, 20),
                            markerDirection: MarkerDirection.heading,
                            accuracyCircleColor:
                                Colors.blue[200]!.withAlpha(0x20),
                            headingSectorColor:
                                Colors.blue[400]!.withAlpha(0x90),
                            headingSectorRadius: 60,
                          ),
                        ),
                        if (state.showLightRail)
                          HomePageMarkerLayer(
                            design: widget.design,
                            model: widget.model,
                            transportType: 'lightRail',
                          ),
                        if (state.showSubway)
                          HomePageMarkerLayer(
                            design: widget.design,
                            model: widget.model,
                            transportType: 'subway',
                          ),
                        if (state.showTram)
                          HomePageMarkerLayer(
                            design: widget.design,
                            model: widget.model,
                            transportType: 'tram',
                          ),
                        if (state.showFerry)
                          HomePageMarkerLayer(
                            design: widget.design,
                            model: widget.model,
                            transportType: 'ferry',
                          ),
                        if (state.showFunicular)
                          HomePageMarkerLayer(
                            design: widget.design,
                            model: widget.model,
                            transportType: 'funicular',
                          ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 20.0, bottom: 160.0),
                            child: FloatingActionButton(
                              shape: const CircleBorder(),
                              onPressed: widget.model.recenterMap,
                              child: Icon(
                                Icons.my_location,
                                color: colors.tertiary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (state.ongoingJourney != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OngoingJourneyBanner(
                  design: widget.design,
                  model: widget.model,
                ),
              ),
          ],
        ),
        bottomSheet: Material(
          color: colors.surfaceContainer,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.model.searchController,
                        onChanged: (v) {},
                        style: TextStyle(color: colors.onPrimaryContainer),
                        decoration: InputDecoration(
                          hintText: 'Where do you want to go?',
                          prefixIcon:
                              Icon(Icons.location_pin, color: colors.primary),
                          filled: true,
                          fillColor: colors.primaryContainer,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      onPressed: () => MapOptionsModal.show(
                        context,
                        widget.model,
                        design: widget.design,
                      ),
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FavesBar(
                  design: widget.design,
                  model: widget.model,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}