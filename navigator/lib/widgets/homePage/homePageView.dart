import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/navigator_maplibre_map.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/open_free_map_bright_layer.dart';
import 'package:navigator/widgets/homePage/UIComponents/favesBar/favesBar.dart';
import 'package:navigator/widgets/homePage/UIComponents/mapOptionsModal/mapOptionsModal.dart';
import 'package:navigator/widgets/homePage/UIComponents/ongoingJourneyBanner/ongoingJourneyBanner.dart';
import 'package:navigator/widgets/homePage/UIComponents/searchResultsCard/searchResultsCard.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/stationSheet/stationSheet.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/homePage/home_station_features.dart';

class HomePageView extends StatefulWidget {
  final HomePageModel model;
  final int design;

  const HomePageView({super.key, required this.model, required this.design});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.model.initializeMap());
    unawaited(widget.model.initializeOngoingJourney());
    unawaited(widget.model.getFaves());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.model.resumeOngoingJourneySync();
      widget.model.resumeMapDataLoading();
    } else {
      widget.model.pauseOngoingJourneySync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                      position: offsetAnimation,
                      child: child,
                    );
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
                            itemCount: widget.model.faves.searchResults.length,
                            itemBuilder: (context, i) {
                              final r = widget.model.faves.searchResults[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                        prefixIcon: Icon(
                          Icons.location_pin,
                          color: colors.primary,
                        ),
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
              FavesBar(design: widget.design, model: widget.model),
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
        final colors = Theme.of(context).colorScheme;
        final pos = widget.model.position;
        final lay = widget.model.layers;
        final jrn = widget.model.journey;
        final overlayLoadingMessage = lay.stations.isEmpty
            ? 'Loading nearby stations…'
            : lay.lines.isEmpty
            ? 'Loading transit lines…'
            : 'Refreshing transit map…';

        final lines = <NavigatorMapLine>[
          if (lay.showSubway) ...lay.subwayLines,
          if (lay.showLightRail) ...lay.lightRailLines,
          if (lay.showTram) ...lay.tramLines,
          if (lay.showFerry) ...lay.ferryLines,
          if (lay.showFunicular) ...lay.funicularLines,
          if (jrn.ongoingJourney != null) ...jrn.polylines,
        ];
        final stationFeatures = buildHomeStationFeatures(widget.model, colors);
        final points = <NavigatorMapPoint>[
          ...stationFeatures.points,
          if (pos.currentUserLocation case final location?)
            _locationPoint(
              location,
              pos.currentZoom,
              pos.locationAccuracy,
              pos.locationHeading,
            ),
        ];

        return Stack(
          children: [
            Positioned.fill(
              child: NavigatorMapLibreMap(
                idPrefix: 'home',
                initialCenter: pos.currentUserLocation ?? pos.currentCenter,
                initialZoom: pos.currentZoom,
                lines: lines,
                points: points,
                onMapReady: widget.model.attachMapCamera,
                onCameraChanged: widget.model.onPositionChanged,
                onPointTap: (key) {
                  final station = stationFeatures.stationsByKey[key];
                  if (station != null) unawaited(onStationTap(station));
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0, bottom: 160.0),
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: widget.model.recenterMap,
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const OpenFreeMapAttribution(
              padding: EdgeInsets.only(left: 4, bottom: 144),
            ),
            if (lay.isOverlayLoading)
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Card(
                      color: colors.inverseSurface,
                      elevation: 6,
                      shadowColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: colors.onInverseSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.inversePrimary,
                                backgroundColor: colors.onInverseSurface
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              overlayLoadingMessage,
                              style: TextStyle(
                                color: colors.onInverseSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (lay.overlayError != null)
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lay.lines.isEmpty && lay.stations.isEmpty
                                  ? 'Transit map unavailable'
                                  : 'Some transit data unavailable',
                            ),
                            TextButton(
                              onPressed: () => unawaited(
                                widget.model.loadMapOverlaysAt(
                                  pos.currentCenter,
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  NavigatorMapPoint _locationPoint(
    LatLng location,
    double zoom,
    double accuracyMeters,
    double heading,
  ) {
    final metersPerPixel =
        156543.03392 *
        math.cos(location.latitude * math.pi / 180) /
        math.pow(2, zoom);
    final accuracyRadius = metersPerPixel <= 0
        ? 0.0
        : (accuracyMeters / metersPerPixel).clamp(0, 120).toDouble();
    return NavigatorMapPoint(
      id: 'current-location',
      point: location,
      color: Colors.lightBlue.shade800,
      strokeColor: Colors.white,
      radius: 10,
      strokeWidth: 2,
      icon: 'navigator-location',
      iconSize: 0.07,
      heading: heading,
      accuracyRadius: accuracyRadius,
      accuracyColor: Colors.blue.shade200.withAlpha(0x20),
      properties: const {'kind': 'currentLocation'},
    );
  }

  Future<void> onStationTap(Station station) async {
    await widget.model.selectStation(station);
    if (!mounted) return;
    await StationSheet.show(
      context,
      widget.model.stationSheetNotifier,
      widget.design,
      station,
      widget.model.navigateLocation,
      widget.model.getDeparturesForStation,
      widget.model.getarrivalsForStation,
    );
    if (mounted) widget.model.deselectStation();
  }
}
