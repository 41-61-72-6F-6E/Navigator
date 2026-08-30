import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

class OpenFreeMapBrightLayer extends StatefulWidget {
  static const styleUrl = 'https://tiles.openfreemap.org/styles/bright';

  const OpenFreeMapBrightLayer({super.key});

  @override
  State<OpenFreeMapBrightLayer> createState() => _OpenFreeMapBrightLayerState();
}

class _OpenFreeMapBrightLayerState extends State<OpenFreeMapBrightLayer> {
  late Future<vt.Style> _styleFuture;
  vt.Style? _style;

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadStyle();
  }

  Future<vt.Style> _loadStyle() async {
    final style = await const vt.StyleReader(
      uri: OpenFreeMapBrightLayer.styleUrl,
    ).read();

    if (mounted) {
      _style = style;
    } else {
      style.dispose();
    }
    return style;
  }

  void _retry() {
    setState(() {
      _styleFuture = _loadStyle();
    });
  }

  @override
  void dispose() {
    _style?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<vt.Style>(
      future: _styleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final style = snapshot.requireData;
          return vt.VectorTileLayer(
            theme: style.theme,
            tileProviders: style.providers,
            rasterSources: style.rasterSources,
            sprites: style.sprites,
          );
        }

        if (snapshot.hasError) {
          return ColoredBox(
            color: const Color(0xFFF8F4F0),
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload map'),
              ),
            ),
          );
        }

        return const ColoredBox(
          color: Color(0xFFF8F4F0),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class OpenFreeMapAttribution extends StatelessWidget {
  final Alignment alignment;
  final EdgeInsets padding;

  const OpenFreeMapAttribution({
    super.key,
    this.alignment = Alignment.bottomLeft,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: padding,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  'OpenFreeMap © OpenMapTiles · Data from OpenStreetMap',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
