import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/subway_line.dart';


class Overpassapi {
  Future<List<SubwayLine>> fetchSubwayLinesWithColors({
    required double lat,
    required double lon,
    required int radius
  }) async {
    final query = '''
[out:json][timeout:60];
// Query around the specified coordinates (default: Berlin)
(
  relation["route"="subway"](around:$radius, $lat, $lon);
  relation["route"="light_rail"](around:$radius, $lat, $lon);
  relation["route"="tram"](around:$radius, $lat, $lon);
  relation["route"="ferry"](around:$radius, $lat, $lon);
  relation["route"="funicular"](around:$radius, $lat, $lon);
)->.r;
.r >> -> .x;
.x out geom;
''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await http.post(url, body: {'data': query});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return parseSubwayLinesFromOverpass(data);
    } else {
      return List<SubwayLine>.empty();
      //throw Exception('Failed to fetch Overpass data');
    }
  }

  // Keep the old method for backward compatibility
  Future<List<List<LatLng>>> fetchSubwayLines({
    required double lat,
    required double lon,
    required int radius
  }) async {
    final subwayLines = await fetchSubwayLinesWithColors(lat: lat, lon: lon, radius: radius);
    return subwayLines.map((line) => line.points).toList();
  }

  List<SubwayLine> parseSubwayLinesFromOverpass(dynamic json) {
    final List<SubwayLine> subwayLines = [];
    
    // First, collect all subway relations with their metadata
    Map<int, Map<String, String>> relationData = {};
    
    for (var element in json['elements']) {
      if (element['type'] == 'relation' && 
          element.containsKey('tags') && 
          (element['tags']['route'] == 'subway' || 
          element['tags']['route'] == 'light_rail' ||
          element['tags']['route'] == 'tram' ||
          // element['tags']['route'] == 'bus' ||
          // element['tags']['route'] == 'trolleybus' ||
          element['tags']['route'] == 'ferry' ||
          element['tags']['route'] == 'funicular')) {
        
        final tags = element['tags'];
        relationData[element['id']] = {
          'color': tags['colour'] ?? tags['color'] ?? '',
          'name': tags['name'] ?? tags['ref'] ?? '',
          'ref': tags['ref'] ?? '',
          'type': tags['route'] ?? ''
        };
      }
    }
    
    // Group ways by their parent relations
    Map<int, List<int>> relationToWays = {};
    
    for (var element in json['elements']) {
      if (element['type'] == 'relation' && relationData.containsKey(element['id'])) {
        relationToWays[element['id']] = [];
        
        if (element.containsKey('members')) {
          for (var member in element['members']) {
            if (member['type'] == 'way') {
              relationToWays[element['id']]!.add(member['ref']);
            }
          }
        }
      }
    }
    
    // Now process each way as a separate polyline
    for (var relationId in relationData.keys) {
      final wayIds = relationToWays[relationId] ?? [];
      final relationInfo = relationData[relationId]!;
      
      // Create a separate SubwayLine for each way segment
      for (var element in json['elements']) {
        if (element['type'] == 'way' && 
            wayIds.contains(element['id']) &&
            element.containsKey('geometry')) {
          
          final geometry = element['geometry'];
          if (geometry is List && geometry.isNotEmpty) {
            final wayPoints = geometry.map<LatLng>((point) {
              return LatLng(point['lat'].toDouble(), point['lon'].toDouble());
            }).toList();
            
            // Create separate polyline for each way segment
            if (wayPoints.length >= 2) {
              subwayLines.add(SubwayLine(
                points: wayPoints,
                color: parseColorFromString(relationInfo['color']),
                lineName: relationInfo['name'],
                lineRef: relationInfo['ref'],
                type: relationInfo['type']
              ));
            }
          }
        }
      }
    }
        
    // Debug: Print some color info
    final uniqueLines = <String, SubwayLine>{};
    for (var line in subwayLines) {
      final key = '${line.lineName}_${line.lineRef}';
      uniqueLines[key] = line;
    }
    
    return subwayLines;
  }

  Future<List<Station>> fetchStationsByType({
    required double lat,
    required double lon,
    required int radius,
  }) async {
    // Query for actual stations and terminals, excluding entrances and platforms
    final query = '''
[out:json][timeout:90];
(
  // Main railway stations
  node["railway"="station"](around:$radius,$lat,$lon);
  node["railway"="halt"](around:$radius,$lat,$lon);
  
  // Tram stops
  node["railway"="tram_stop"](around:$radius,$lat,$lon);
  
  // Metro/subway stations
  node["station"="subway"](around:$radius,$lat,$lon);
  
  // Light rail stations
  node["station"="light_rail"](around:$radius,$lat,$lon);
  
  // Ferry terminals/stops
  node["amenity"="ferry_terminal"](around:$radius,$lat,$lon);
  node["public_transport"="station"]["ferry"="yes"](around:$radius,$lat,$lon);
);
out body;
''';

    try {
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(
          url,
          body: {'data': query},
          headers: {'User-Agent': 'Navigator Public Transport App'}
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return parseStationsFromOverpass(data);
      } else {
        print('Overpass API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch station data');
      }
    } catch (e) {
      print('Exception during station fetch: $e');
      throw Exception('Failed to fetch station data');
    }
  }

  List<Station> parseStationsFromOverpass(dynamic json) {
    final List<Station> stations = [];

    for (var element in json['elements']) {
      if (element['type'] == 'node' && element.containsKey('tags')) {
        final tags = element['tags'];
        final name = tags['name'] ?? tags['ref'] ?? 'Unknown Station';

        // Skip elements without names or that are explicitly entrances
        if (name == 'Unknown Station' || tags['railway'] == 'subway_entrance') {
          continue;
        }

        // Determine station types based on OSM tags
        final bool isSubway = tags['subway'] == 'yes' ||
            tags['station'] == 'subway';

        final bool isLightRail = tags['light_rail'] == 'yes' ||
            tags['station'] == 'light_rail';

        final bool isTram = tags['tram'] == 'yes' ||
            tags['railway'] == 'tram_stop';

        final bool isFerry = tags['ferry'] == 'yes' ||
            tags['amenity'] == 'ferry_terminal';

        final bool isRailStation = tags['railway'] == 'station' ||
            tags['railway'] == 'halt';

        final bool isNational = tags['train'] == 'yes' ||
            tags['service'] == 'long_distance' ||
            (isRailStation && tags['station'] == 'rail');

        stations.add(Station(
          type: 'station',
          id: element['id'].toString(),
          name: name,
          latitude: element['lat'].toDouble(),
          longitude: element['lon'].toDouble(),
          nationalExpress: tags['national_express'] == 'yes',
          national: isNational,
          regional: tags['regional'] == 'yes',
          regionalExpress: tags['regional_express'] == 'yes',
          suburban: isLightRail || tags['suburban'] == 'yes',
          bus: tags['bus'] == 'yes',
          ferry: isFerry,
          subway: isSubway,
          tram: isTram,
          taxi: tags['taxi'] == 'yes', ril100Ids: [],
        ));
      }
    }
    return stations;
  }

  // Transit line color fetching method
  Future<Color> getTransitLineColor({
    required double lat,
    required double lon,
    required String lineName,
    String? lineRef,
    String? mode,
    int radius = 3000
  }) async {
    // Default colors by transport mode
    final Map<String, Color> defaultColors = {
      'train': const Color(0xFF006CB3),     // Blue for S-Bahn/Train
      'subway': const Color(0xFF00629E),    // Dark blue for U-Bahn
      'tram': const Color(0xFFE4000F),      // Red for trams
      'bus': const Color(0xFF9A258F),       // Purple for buses
      'ferry': const Color(0xFF0098D8),     // Light blue for ferries
      'light_rail': const Color(0xFF006CB3),// Same as train
      'funicular': const Color(0xFFE77817), // Orange for funicular
    };

    try {
      // Clean up line name and ref
      String cleanLineName = lineName.trim();
      String? cleanLineRef = lineRef?.trim();
      String transportType = mode?.toLowerCase() ?? 'train';

      // Convert mode to Overpass route type
      String routeType = _getRouteType(transportType, cleanLineName);
      
      // Extract core identifier (the actual line number/letter)
      String coreId = _extractCoreIdentifier(cleanLineName, cleanLineRef);

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      
      // Try queries in order of specificity
      final queries = _buildOptimizedQueries(coreId, routeType, radius, lat, lon);
      
      for (int i = 0; i < queries.length; i++) {
        //print('=== Trying Query ${i + 1}/${queries.length} ===');
        
        final response = await http.post(url, body: {'data': queries[i]});
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['elements'] != null && data['elements'] is List) {
            final elements = data['elements'] as List;
            
            if (elements.isNotEmpty) {
              //print('Found ${elements.length} route(s)');
              
              // Find the best match
              final matchedRoute = _findBestRouteMatch(
                elements,
                coreId,
                routeType,
                cleanLineName,
                cleanLineRef
              );

              if (matchedRoute != null) {
                final tags = matchedRoute['tags'];
                final colorStr = tags['colour'] ?? tags['color'];
                
                if (colorStr != null && colorStr.isNotEmpty) {
                  //print('Found color: $colorStr');
                  return parseColorFromString(colorStr);
                } else {
                  //print('Route found but no color specified');
                }
              }
            }
          }
        } else {
          print('Query failed with status: ${response.statusCode}');
        }
      }
      
      print('No matching route found, using default color for $routeType');
      return defaultColors[routeType] ?? Colors.blue;
      
    } catch (e) {
      print('Error fetching transit line color: $e');
      return Colors.blue;
    }
  }

  String _getRouteType(String transportType, String lineName) {
    switch (transportType) {
      case 'subway': return 'subway';
      case 'tram': return 'tram';
      case 'bus': return 'bus';
      case 'ferry': return 'ferry';
      case 'regional': return 'train';
      case 'suburban': return 'light_rail';
      default:
        // Smart detection based on line name patterns
        String upperName = lineName.toUpperCase();
        if (upperName.startsWith('STR') || upperName.contains('TRAM')) {
          return 'tram';
        } else if (upperName.startsWith('S ') || upperName.startsWith('S-')) {
          return 'light_rail';
        } else if (upperName.startsWith('U ') || upperName.startsWith('U-')) {
          return 'subway';
        } else if (upperName.contains('BUS')) {
          return 'bus';
        } else {
          return 'train';
        }
    }
  }

  String _extractCoreIdentifier(String lineName, String? lineRef) {
    // Priority: Use lineRef if it's a simple identifier
    if (lineRef != null && lineRef.isNotEmpty) {
      String cleaned = lineRef.trim();
      // If lineRef is simple (no special chars, short), use it
      if (cleaned.length <= 10 && !cleaned.contains('#') && !cleaned.contains('::')) {
        return _normalizeIdentifier(cleaned);
      }
    }
    
    // Otherwise extract from line name
    return _normalizeIdentifier(lineName);
  }

  String _normalizeIdentifier(String input) {
    return input
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'^(STR|TRAM|BUS|LINE|S|U)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\w]'), ''); // Remove special characters
  }

  List<String> _buildOptimizedQueries(
    String coreId,
    String routeType,
    int radius,
    double lat,
    double lon
  ) {
    List<String> queries = [];
    
    // Query 1: Exact ref match (most reliable)
    if (coreId.isNotEmpty) {
      queries.add('''
[out:json][timeout:25];
(
  relation["type"="route"]["route"="$routeType"]["ref"="$coreId"](around:$radius, $lat, $lon);
)->.routes;
.routes out tags;
''');
    }
    
    // Query 2: Ref with common patterns (S 3, S3, etc.)
    if (coreId.isNotEmpty) {
      queries.add('''
[out:json][timeout:25];
(
  relation["type"="route"]["route"="$routeType"]["ref"~"^$coreId\$|^$coreId\\s|\\s$coreId\$"](around:$radius, $lat, $lon);
)->.routes;
.routes out tags;
''');
    }
    
    // Query 3: Name contains identifier
    if (coreId.isNotEmpty) {
      queries.add('''
[out:json][timeout:25];
(
  relation["type"="route"]["route"="$routeType"]["name"~"$coreId"](around:$radius, $lat, $lon);
)->.routes;
.routes out tags;
''');
    }
    
    // Query 4: Broader route type search (for similar transport types)
    List<String> similarTypes = _getSimilarRouteTypes(routeType);
    if (similarTypes.isNotEmpty && coreId.isNotEmpty) {
      String typePattern = similarTypes.join('|');
      queries.add('''
[out:json][timeout:25];
(
  relation["type"="route"]["route"~"^($typePattern)\$"]["ref"="$coreId"](around:$radius, $lat, $lon);
)->.routes;
.routes out tags;
''');
    }
    
    return queries;
  }

  List<String> _getSimilarRouteTypes(String routeType) {
    switch (routeType) {
      case 'train':
        return ['train', 'light_rail', 'subway'];
      case 'light_rail':
        return ['light_rail', 'train', 'subway'];
      case 'subway':
        return ['subway', 'train', 'light_rail'];
      case 'tram':
        return ['tram', 'light_rail'];
      default:
        return [];
    }
  }

  Map<String, dynamic>? _findBestRouteMatch(
    List<dynamic> elements,
    String targetCoreId,
    String expectedRouteType,
    String originalLineName,
    String? originalLineRef
  ) {
    if (elements.isEmpty) return null;
    
    Map<String, dynamic>? bestMatch;
    int bestScore = 0;
    
    for (var element in elements) {
      if (element['tags'] == null) continue;
      
      final tags = element['tags'];
      final String? elementRef = tags['ref'];
      final String? elementName = tags['name'];
      final String? elementRoute = tags['route'];
      final String? elementColor = tags['colour'] ?? tags['color'];
            
      int score = _calculateRouteScore(
        targetCoreId,
        expectedRouteType,
        elementRef,
        elementName,
        elementRoute,
        elementColor != null
      );
      
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = element;
      }
    }
    
    return bestScore >= 50 ? bestMatch : null; // Minimum threshold
  }

  int _calculateRouteScore(
    String targetCoreId,
    String expectedRouteType,
    String? elementRef,
    String? elementName,
    String? elementRoute,
    bool hasColor
  ) {
    int score = 0;
    
    // Route type matching (essential)
    if (elementRoute == expectedRouteType) {
      score += 100;
    } else if (_getSimilarRouteTypes(expectedRouteType).contains(elementRoute)) {
      score += 50;
    } else {
      score -= 200; // Heavy penalty for wrong type
    }
    
    // Reference matching (most important for identification)
    if (elementRef != null && targetCoreId.isNotEmpty) {
      String normalizedRef = _normalizeIdentifier(elementRef);
      if (normalizedRef == targetCoreId) {
        score += 500; // Exact match
      } else if (normalizedRef.contains(targetCoreId) || targetCoreId.contains(normalizedRef)) {
        score += 250; // Partial match
      }
    }
    
    // Name matching (secondary)
    if (elementName != null && targetCoreId.isNotEmpty) {
      String normalizedName = _normalizeIdentifier(elementName);
      if (normalizedName.contains(targetCoreId)) {
        score += 100;
      }
    }
    
    // Bonus for having color information
    if (hasColor) {
      score += 50;
    }
    
    return score;
  }

  Color parseColorFromString(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return Colors.blue;
    }

    // Handle hex colors with or without # prefix
    String normalizedColor = colorStr.trim().toLowerCase();
    
    // Handle named colors (common in OSM)
    final Map<String, String> namedColors = {
      'red': 'ff0000',
      'blue': '0000ff',
      'green': '00ff00',
      'yellow': 'ffff00',
      'orange': 'ffa500',
      'purple': '800080',
      'pink': 'ffc0cb',
      'brown': 'a52a2a',
      'gray': '808080',
      'grey': '808080',
      'black': '000000',
      'white': 'ffffff',
    };
    
    if (namedColors.containsKey(normalizedColor)) {
      normalizedColor = namedColors[normalizedColor]!;
    } else {
      // Remove # prefix if present
      normalizedColor = normalizedColor.startsWith('#') ? normalizedColor.substring(1) : normalizedColor;
    }

    // Handle 3-digit hex codes (expand to 6 digits)
    if (normalizedColor.length == 3) {
      normalizedColor = normalizedColor.split('').map((c) => '$c$c').join('');
    }

    // Add alpha channel if missing
    if (normalizedColor.length == 6) {
      normalizedColor = 'FF$normalizedColor';
    }

    try {
      return Color(int.parse(normalizedColor, radix: 16));
    } catch (e) {
      print('Invalid color format: $colorStr');
      return Colors.blue;
    }
  }
}