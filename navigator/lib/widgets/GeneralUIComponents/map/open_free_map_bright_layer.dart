import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:navigator/widgets/GeneralUIComponents/map/curated_map_theme.dart';

typedef MapStyleFetcher = Future<String> Function(Uri uri);

class OpenFreeMapStyleLoader {
  static const styleUrl = 'https://tiles.openfreemap.org/styles/bright';
  static final OpenFreeMapStyleLoader instance = OpenFreeMapStyleLoader();

  final MapStyleFetcher _fetchStyle;
  Future<String>? _cachedStyle;

  OpenFreeMapStyleLoader({MapStyleFetcher? fetchStyle})
    : _fetchStyle = fetchStyle ?? _defaultFetch;

  Future<String> load() => _cachedStyle ??= _load();

  void invalidate() {
    _cachedStyle = null;
  }

  Future<String> _load() async {
    try {
      final body = await _fetchStyle(Uri.parse(styleUrl));
      final source = jsonDecode(body) as Map<String, dynamic>;
      return jsonEncode(CuratedMapTheme.curate(source));
    } catch (_) {
      _cachedStyle = null;
      rethrow;
    }
  }

  static Future<String> _defaultFetch(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Map style request failed (${response.statusCode})');
    }
    return utf8.decode(response.bodyBytes);
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
