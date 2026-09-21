import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:navigator/widgets/GeneralUIComponents/map/map_feature.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/map_geojson.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/maplibre_camera.dart';
import 'package:navigator/widgets/GeneralUIComponents/map/open_free_map_bright_layer.dart';

typedef NavigatorMapCameraChanged =
    void Function(LatLng center, double zoom, bool hasGesture);

/// A hardware-accelerated MapLibre map with persistent GeoJSON sources.
///
/// Updating routes, stations, or the location only updates source data. The
/// native map view and its style layers remain mounted while Flutter rebuilds.
class NavigatorMapLibreMap extends StatefulWidget {
  final String idPrefix;
  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<NavigatorMapLine> lines;
  final List<NavigatorMapPoint> points;
  final ValueChanged<NavigatorMapCamera>? onMapReady;
  final NavigatorMapCameraChanged? onCameraChanged;
  final ValueChanged<String>? onPointTap;

  const NavigatorMapLibreMap({
    super.key,
    required this.idPrefix,
    required this.initialCenter,
    required this.initialZoom,
    required this.lines,
    required this.points,
    this.minZoom = 3,
    this.maxZoom = 18,
    this.onMapReady,
    this.onCameraChanged,
    this.onPointTap,
  });

  @override
  State<NavigatorMapLibreMap> createState() => _NavigatorMapLibreMapState();
}

class _NavigatorMapLibreMapState extends State<NavigatorMapLibreMap> {
  late Future<String> _styleFuture;
  ml.MapController? _controller;
  ml.StyleController? _style;
  bool _styleConfigured = false;
  bool _gestureMove = false;
  int _styleGeneration = 0;

  String get _lineSourceId => '${widget.idPrefix}-lines';
  String get _pointSourceId => '${widget.idPrefix}-points';
  String get _lineBorderLayerId => '${widget.idPrefix}-line-border';
  String get _lineSolidLayerId => '${widget.idPrefix}-line-solid';
  String get _lineDashedLayerId => '${widget.idPrefix}-line-dashed';
  String get _accuracyLayerId => '${widget.idPrefix}-point-accuracy';
  String get _pointLayerId => '${widget.idPrefix}-point-circle';
  String get _iconLayerId => '${widget.idPrefix}-point-icon';
  String get _labelLayerId => '${widget.idPrefix}-point-label';

  @override
  void initState() {
    super.initState();
    _styleFuture = OpenFreeMapStyleLoader.instance.load();
  }

  @override
  void didUpdateWidget(covariant NavigatorMapLibreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines != widget.lines || oldWidget.points != widget.points) {
      unawaited(_updateSources());
    }
  }

  void _retryStyle() {
    OpenFreeMapStyleLoader.instance.invalidate();
    setState(() {
      _styleFuture = OpenFreeMapStyleLoader.instance.load();
    });
  }

  void _onMapCreated(ml.MapController controller) {
    _controller = controller;
    widget.onMapReady?.call(MapLibreCamera(controller));
  }

  void _onStyleLoaded(ml.StyleController style) {
    final generation = ++_styleGeneration;
    _style = style;
    _styleConfigured = false;
    unawaited(_configureStyle(style, generation));
  }

  Future<void> _configureStyle(ml.StyleController style, int generation) async {
    try {
      await style.addSource(
        ml.GeoJsonSource(
          id: _lineSourceId,
          data: MapGeoJson.lines(widget.lines),
        ),
      );
      await style.addSource(
        ml.GeoJsonSource(
          id: _pointSourceId,
          data: MapGeoJson.mapPoints(widget.points),
        ),
      );

      await Future.wait([
        style.addImageFromIconData(
          id: 'navigator-transit',
          iconData: Icons.directions_transit,
          color: Colors.white,
        ),
        style.addImageFromIconData(
          id: 'navigator-start',
          iconData: Icons.trip_origin,
          color: Colors.white,
        ),
        style.addImageFromIconData(
          id: 'navigator-finish',
          iconData: Icons.location_on,
          color: Colors.white,
        ),
        style.addImageFromIconData(
          id: 'navigator-location',
          iconData: Icons.navigation,
          color: Colors.white,
        ),
      ]);

      await style.addLayer(
        ml.LineStyleLayer(
          id: _lineBorderLayerId,
          sourceId: _lineSourceId,
          filter: const [
            '>',
            ['get', 'borderWidth'],
            0,
          ],
          layout: const {'line-cap': 'round', 'line-join': 'round'},
          paint: const {
            'line-color': ['get', 'borderColor'],
            'line-width': [
              '+',
              ['get', 'width'],
              ['get', 'borderWidth'],
            ],
          },
        ),
      );
      await style.addLayer(
        ml.LineStyleLayer(
          id: _lineSolidLayerId,
          sourceId: _lineSourceId,
          filter: const [
            '==',
            ['get', 'dashed'],
            false,
          ],
          layout: const {'line-cap': 'round', 'line-join': 'round'},
          paint: const {
            'line-color': ['get', 'color'],
            'line-width': ['get', 'width'],
          },
        ),
      );
      await style.addLayer(
        ml.LineStyleLayer(
          id: _lineDashedLayerId,
          sourceId: _lineSourceId,
          filter: const [
            '==',
            ['get', 'dashed'],
            true,
          ],
          layout: const {'line-cap': 'round', 'line-join': 'round'},
          paint: const {
            'line-color': ['get', 'color'],
            'line-width': ['get', 'width'],
            'line-dasharray': [1.5, 2.0],
          },
        ),
      );
      await style.addLayer(
        ml.CircleStyleLayer(
          id: _accuracyLayerId,
          sourceId: _pointSourceId,
          filter: const [
            '>',
            ['get', 'accuracyRadius'],
            0,
          ],
          paint: const {
            'circle-radius': ['get', 'accuracyRadius'],
            'circle-color': ['get', 'accuracyColor'],
            'circle-stroke-width': 0,
          },
        ),
      );
      await style.addLayer(
        ml.CircleStyleLayer(
          id: _pointLayerId,
          sourceId: _pointSourceId,
          paint: const {
            'circle-radius': ['get', 'radius'],
            'circle-color': ['get', 'color'],
            'circle-stroke-color': ['get', 'strokeColor'],
            'circle-stroke-width': ['get', 'strokeWidth'],
          },
        ),
      );
      await style.addLayer(
        ml.SymbolStyleLayer(
          id: _iconLayerId,
          sourceId: _pointSourceId,
          filter: const [
            '!=',
            ['get', 'icon'],
            '',
          ],
          layout: const {
            'icon-image': ['get', 'icon'],
            'icon-size': ['get', 'iconSize'],
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
          },
        ),
      );
      await style.addLayer(
        ml.SymbolStyleLayer(
          id: _labelLayerId,
          sourceId: _pointSourceId,
          filter: const [
            '==',
            ['get', 'showLabel'],
            true,
          ],
          layout: const {
            'text-field': ['get', 'label'],
            'text-size': 11,
            'text-offset': [0, -1.8],
            'text-anchor': 'bottom',
            'text-optional': true,
          },
          paint: const {
            'text-color': ['get', 'labelColor'],
            'text-halo-color': ['get', 'labelHaloColor'],
            'text-halo-width': 2,
          },
        ),
      );

      if (!mounted || generation != _styleGeneration) return;
      _styleConfigured = true;
      await _updateSources();
    } catch (error, stackTrace) {
      debugPrint('Unable to configure MapLibre overlays: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _updateSources() async {
    final style = _style;
    if (!_styleConfigured || style == null) return;
    try {
      await Future.wait([
        style.updateGeoJsonSource(
          id: _lineSourceId,
          data: MapGeoJson.lines(widget.lines),
        ),
        style.updateGeoJsonSource(
          id: _pointSourceId,
          data: MapGeoJson.mapPoints(widget.points),
        ),
      ]);
    } catch (error) {
      debugPrint('Unable to update MapLibre overlays: $error');
    }
  }

  void _onMapEvent(ml.MapEvent event) {
    switch (event) {
      case ml.MapEventStartMoveCamera(:final reason):
        _gestureMove = reason == ml.CameraChangeReason.apiGesture;
      case ml.MapEventMoveCamera(:final camera):
        widget.onCameraChanged?.call(
          fromGeographic(camera.center),
          camera.zoom,
          _gestureMove,
        );
      case ml.MapEventCameraIdle():
        _gestureMove = false;
      case ml.MapEventClick(:final screenPoint):
        _handlePointTap(screenPoint);
      default:
        break;
    }
  }

  void _handlePointTap(Offset screenPoint) {
    final controller = _controller;
    final callback = widget.onPointTap;
    if (controller == null || callback == null) return;

    final features = controller.featuresAtPoint(
      screenPoint,
      layerIds: [_iconLayerId, _pointLayerId, _labelLayerId],
    );
    for (final feature in features) {
      final key = feature.properties['featureKey'];
      if (key is String && key.isNotEmpty) {
        callback(key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _styleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: _retryStyle,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry map'),
              ),
            ),
          );
        }
        final style = snapshot.data;
        if (style == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ml.MapLibreMap(
          key: ValueKey('${widget.idPrefix}-maplibre'),
          options: ml.MapOptions(
            initStyle: style,
            initCenter: toGeographic(widget.initialCenter),
            initZoom: widget.initialZoom,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            gestures: const ml.MapGestures.all(pitch: false),
            androidTextureMode: false,
            androidMode: ml.AndroidPlatformViewMode.hc,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoaded: _onStyleLoaded,
          onEvent: _onMapEvent,
        );
      },
    );
  }
}
