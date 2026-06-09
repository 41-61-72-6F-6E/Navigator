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
import 'package:navigator/widgets/homePage/UIComponents/stationSheet/stationSheet.dart';
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
    widget.model.initiateLines();
    widget.model.fetchStations();
    widget.model.setInitialUserLocation(this);
    widget.model.initializeOngoingJourney();
    widget.model.getFaves();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.model.updateBrightness(
      Theme.of(context).colorScheme.brightness == Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          // ── Search results vs map ──────────────────────────────────────
          ListenableBuilder(
            listenable: widget.model.faves,
            builder: (context, _) {
              final hasResults = widget.model.faves.searchResults.isNotEmpty;
              const bottomSheetHeight = 96.0;

              return WillPopScope(
                onWillPop: () async {
                  if (hasResults) {
                    widget.model.clearSearch();
                    return false;
                  }
                  return true;
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(anim);
                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                  child: hasResults
                      ? SafeArea(
                          child: ListView.builder(
                            key: const ValueKey('list'),
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, bottomSheetHeight + 16),
                            itemCount:
                                widget.model.faves.searchResults.length,
                            itemBuilder: (context, i) {
                              final r =
                                  widget.model.faves.searchResults[i];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
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
                      : _buildMap(context),
                ),
              );
            },
          ),

          // ── Ongoing journey banner ─────────────────────────────────────
          ListenableBuilder(
            listenable: widget.model.journey,
            builder: (context, _) {
              if (widget.model.journey.ongoingJourney == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OngoingJourneyBanner(
                  design: widget.design,
                  model: widget.model,
                ),
              );
            },
          ),
        ],
      ),

      // ── Bottom sheet ────────────────────────────────────────────────────
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
    );
  }

  Widget _buildMap(BuildContext context) {
    return ListenableBuilder(
      key: const ValueKey('map'),
      listenable: Listenable.merge([
        widget.model.position,
        widget.model.layers,
        widget.model.journey,
      ]),
      builder: (context, _) {
        final pos = widget.model.position;
        final lay = widget.model.layers;
        final jrn = widget.model.journey;

        return FlutterMap(
          mapController: widget.model.mapController,
          options: MapOptions(
            initialCenter: pos.currentUserLocation ?? pos.currentCenter,
            initialZoom: pos.currentZoom,
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
            if (lay.showSubway)
              PolylineLayer(polylines: lay.subwayLines),
            if (lay.showLightRail)
              PolylineLayer(polylines: lay.lightRailLines),
            if (lay.showTram)
              PolylineLayer(polylines: lay.tramLines),
            if (lay.showFerry)
              PolylineLayer(polylines: lay.ferryLines),
            if (lay.showFunicular)
              PolylineLayer(polylines: lay.funicularLines),
            if (jrn.ongoingJourney != null && jrn.polylines.isNotEmpty)
              PolylineLayer(polylines: jrn.polylines),
            CurrentLocationLayer(
              alignPositionStream:
                  widget.model.alignPositionStreamController.stream,
              alignPositionOnUpdate: pos.alignPositionOnUpdate,
              style: LocationMarkerStyle(
                marker:
                    DefaultLocationMarker(color: Colors.lightBlue[800]!),
                markerSize: const Size(20, 20),
                markerDirection: MarkerDirection.heading,
                accuracyCircleColor: Colors.blue[200]!.withAlpha(0x20),
                headingSectorColor: Colors.blue[400]!.withAlpha(0x90),
                headingSectorRadius: 60,
              ),
            ),
            if (lay.showLightRail)
              HomePageMarkerLayer(
                design: widget.design,
                model: widget.model,
                transportType: 'lightRail',
                onStationTap: (station) => onStationTap(station),
              ),
            if (lay.showSubway)
              HomePageMarkerLayer(
                design: widget.design,
                model: widget.model,
                transportType: 'subway',
                onStationTap: (station) => onStationTap(station),
              ),
            if (lay.showTram)
              HomePageMarkerLayer(
                design: widget.design,
                model: widget.model,
                transportType: 'tram',
                onStationTap: (station) => onStationTap(station),
              ),
            if (lay.showFerry)
              HomePageMarkerLayer(
                design: widget.design,
                model: widget.model,
                transportType: 'ferry',
                onStationTap: (station) => onStationTap(station),
              ),
            if (lay.showFunicular)
              HomePageMarkerLayer(
                design: widget.design,
                model: widget.model,
                transportType: 'funicular',
                onStationTap: (station) => onStationTap(station),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 20.0, bottom: 160.0),
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: widget.model.recenterMap,
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void onStationTap(Station station) {
    widget.model.selectStation(station);
    StationSheet.show(context, widget.model, widget.design, station);
  }

}