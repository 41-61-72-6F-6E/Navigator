import 'dart:convert';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/journeySettings.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:http/http.dart' as http;
import 'package:navigator/env/env.dart';
import 'package:navigator/models/leg.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'dart:convert';
import 'dart:io';

import 'package:navigator/models/trip.dart';

class dbApiService {
  final base_url = Env.api_url;

  Future<List<Journey>> fetchJourneysByLocation(
      Location from,
      Location to,
      DateAndTime when,
      bool departure,
      JourneySettings? journeySettings,
      ) async {
    final queryParams = <String, String>{};

    // Helper to build address string as "City, Street HouseNumber"
    String buildAddress(geo.Placemark placemark) {
      final city = placemark.locality ?? '';
      final street = placemark.street ?? '';
      return city.isNotEmpty && street.isNotEmpty ? '$city, $street' : city + street;
    }

    // FROM handling
    if ((from.type == 'station' || from.type == 'stop') && (from.id.isNotEmpty)) {
      queryParams['from'] = from.id;
    } else {
      queryParams['from.latitude'] = from.latitude.toString();
    }
    queryParams['from.longitude'] = from.longitude.toString();

    try {
      final placemarks = await geo.placemarkFromCoordinates(from.latitude, from.longitude);
      if (placemarks.isNotEmpty) {
        queryParams['from.address'] = buildAddress(placemarks.first);
      }
    } catch (e) {
      print('Error getting address for from location: $e');
    }

    // TO handling
    if ((to.type == 'station' || to.type == 'stop') && (to.id.isNotEmpty)) {
      queryParams['to'] = to.id;
    } else {
      queryParams['to.latitude'] = to.latitude.toString();
    }
    queryParams['to.longitude'] = to.longitude.toString();

    try {
      final placemarks = await geo.placemarkFromCoordinates(to.latitude, to.longitude);
      if (placemarks.isNotEmpty) {
        queryParams['to.address'] = buildAddress(placemarks.first);
      }
    } catch (e) {
      print('Error getting address for to location: $e');
    }

    // Time handling
    final timeParam = when.ISO8601String();
    if (departure) {
      queryParams['departure'] = timeParam;
    } else {
      queryParams['arrival'] = timeParam;
    }

    // Add Settings parameters
    final serviceParams = journeySettings?.toJson();
    serviceParams?.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });

    queryParams['results'] = '3';
    queryParams['stopovers'] = 'true';

    final uri = Uri.http(base_url, '/journeys', queryParams);
    print('Request URI: $uri');

    try {
      final response = await http.get(uri);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Check if journeys key exists and is not null
        if (data['journeys'] == null) {
          print('No journeys found in response');
          return [];
        }

        // Use the parseAndSort method to parse and sort journeys by actual departure time
        return Journey.parseAndSort(data['journeys']);
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load journeys: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Exception in fetchJourneysByLocation: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  Future<Journey> refreshJourneybyToken(String token) async {
    final encodedToken = Uri.encodeComponent(token);
    final url = 'http://$base_url/journeys/$encodedToken?polylines=true&stopovers=true';
    final uri = Uri.parse(url);

    print('Refreshing journey with token: $token');
    print('Final URI: $uri');

    try {
      final response = await http.get(uri);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data is Map<String, dynamic>) {
          final journeyJson = data['journey'];

          return Journey.parseSingleJourneyResponse(journeyJson);
        } else {
          throw FormatException('Unexpected response format: expected a JSON object.');
        }
      } else {
        throw HttpException(
          'Failed to refresh journey. Status code: ${response.statusCode}',
          uri: uri,
        );
      }
    } catch (e, stackTrace) {
      print('Exception in refreshJourney: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Could not refresh journey: $e');
    }
  }

  Future<Trip> fetchTripById(String tripId, {
  bool stopovers = true,
  bool remarks = true,
  bool polyline = false,
  String language = 'en',
  bool pretty = true,
}) async {
  print('DEBUG: Fetching trip with ID: $tripId');
  
  if (tripId.isEmpty) {
    throw ArgumentError('Trip ID cannot be empty');
  }
  
  final queryParams = <String, String>{
    'stopovers': stopovers.toString(),
    'remarks': remarks.toString(),
    'polyline': polyline.toString(),
    'language': language,
    'pretty': pretty.toString(),
  };

  // Based on your API responses, use standard URI encoding first
  final encodedTripId = Uri.encodeComponent(tripId);
  
  try {
    final queryString = queryParams.entries
        .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    
    final url = 'http://$base_url/trips/$encodedTripId?$queryString';
    print('DEBUG: Request URL: $url');
    
    final response = await http.get(Uri.parse(url));
    print('DEBUG: Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      // Handle the nested structure from your API response
      Map<String, dynamic> tripData;
      if (data['trip'] != null) {
        tripData = data['trip'];
      } else if (data is Map<String, dynamic>) {
        tripData = data;
      } else {
        throw FormatException('Unexpected response format: expected trip object');
      }
      
      print('DEBUG: Successfully fetched trip: ${tripData['line']?['name'] ?? 'Unknown'}');
      return Trip.fromJson(data);
      
    } else if (response.statusCode == 404) {
      print('WARNING: Trip not found: $tripId');
      throw HttpException('Trip not found or may have expired', uri: Uri.parse(url));
      
    } else if (response.statusCode == 500) {
      print('WARNING: Server error for trip: $tripId');
      print('DEBUG: Response body: ${response.body}');
      
      // Check if it's a temporary server issue
      if (response.body.contains('error') || response.body.isEmpty) {
        throw HttpException('Temporary server error - trip may be unavailable', uri: Uri.parse(url));
      } else {
        throw HttpException('Server error for trip: $tripId', uri: Uri.parse(url));
      }
      
    } else {
      print('WARNING: HTTP ${response.statusCode} for trip: $tripId');
      print('DEBUG: Response: ${response.body}');
      throw HttpException(
        'Failed to load trip. Status code: ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }
    
  } catch (e, stackTrace) {
    print('ERROR: Exception fetching trip $tripId: $e');
    print('DEBUG: Stack trace: $stackTrace');
    rethrow;
  }
}

   Future<Trip> fetchTripFromLeg(Leg leg, {
    bool stopovers = true,
    bool remarks = true,
    bool polyline = false,
    String language = 'en',
    bool pretty = true,
  }) async {
    if (leg.tripID == null || leg.tripID!.isEmpty) {
      throw ArgumentError('Leg does not contain a valid trip ID');
    }
    
    return fetchTripById(
      leg.tripID!,
      stopovers: stopovers,
      remarks: remarks,
      polyline: polyline,
      language: language,
      pretty: pretty,
    );
  }

  Future<List<Trip>> fetchMultipleTrips(List<String> tripIds, {
    bool stopovers = true,
    bool remarks = true,
    bool polyline = false,
    String language = 'en',
    bool pretty = true,
  }) async {
    List<Trip> trips = [];
    
    for (String tripId in tripIds) {
      try {
        final trip = await fetchTripById(
          tripId,
          stopovers: stopovers,
          remarks: remarks,
          polyline: polyline,
          language: language,
          pretty: pretty,
        );
        trips.add(trip);
      } catch (e) {
        print('Failed to fetch trip $tripId: $e');
        // Continue with other trips instead of failing completely
      }
    }
    
    return trips;
  }

  Future<Journey> refreshJourney(Journey journey) async {
    final encodedToken = Uri.encodeComponent(journey.refreshToken);
    final url = 'http://$base_url/journeys/$encodedToken?polylines=true&stopovers=true';
    final uri = Uri.parse(url);

    print('Refreshing journey with token: ${journey.refreshToken}');
    print('Final URI: $uri');

    try {
      final response = await http.get(uri);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data is Map<String, dynamic>) {
          final journeyJson = data['journey'];

          return Journey.parseSingleJourneyResponse(journeyJson);
        } else {
          throw FormatException('Unexpected response format: expected a JSON object.');
        }
      } else {
        throw HttpException(
          'Failed to refresh journey. Status code: ${response.statusCode}',
          uri: uri,
        );
      }
    } catch (e, stackTrace) {
      print('Exception in refreshJourney: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Could not refresh journey: $e');
    }
  }

  Future<List<Location>> fetchLocations(String query) async {
    final uri = Uri.http(base_url, '/locations', {
      'poi': 'false',
      'addresses': 'true',
      'query': query,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Locations response: ${jsonEncode(data)}');

        return (data as List)
            .where((item) => item != null && (
            (item['id'] != null && item['id'].toString().toLowerCase() != 'null') ||
                (item['type'] != 'station' && item['latitude'] != null && item['longitude'] != null)
        ))
            .map<Location>((item) {
          try {
            if (item['type'] == 'station' || item['type'] == 'stop') {
              // Use Station.fromJson which now properly handles RIL100 IDs
              return Station.fromJson(item);
            } else {
              return Location.fromJson(item);
            }
          } catch (e) {
            print('Error parsing location item: $e');
            print('Item: $item');
            
            // Enhanced fallback for stations/stops to preserve RIL100 IDs if possible
            if (item['type'] == 'station' || item['type'] == 'stop') {
              try {
                // Try to create a Station with available data
                final location = item['location'];
                final products = item['products'];
                
                // Parse RIL100 IDs if available
                List<String> ril100Ids = [];
                if (item['ril100Ids'] != null) {
                  ril100Ids = List<String>.from(item['ril100Ids']);
                } else if (item['station']?['ril100Ids'] != null) {
                  ril100Ids = List<String>.from(item['station']['ril100Ids']);
                }
                
                return Station(
                  id: item['id']?.toString() ?? '',
                  name: item['name']?.toString() ?? 'Unknown',
                  type: item['type']?.toString() ?? 'station',
                  latitude: location?['latitude']?.toDouble() ?? item['latitude']?.toDouble() ?? 0.0,
                  longitude: location?['longitude']?.toDouble() ?? item['longitude']?.toDouble() ?? 0.0,
                  nationalExpress: products?['nationalExpress'] ?? false,
                  national: products?['national'] ?? false,
                  regional: products?['regional'] ?? false,
                  regionalExpress: products?['regionalExpress'] ?? false,
                  suburban: products?['suburban'] ?? false,
                  bus: products?['bus'] ?? false,
                  ferry: products?['ferry'] ?? false,
                  subway: products?['subway'] ?? false,
                  tram: products?['tram'] ?? false,
                  taxi: products?['taxi'] ?? false,
                  ril100Ids: ril100Ids,
                );
              } catch (stationError) {
                print('Failed to create Station fallback: $stationError');
                // Fall back to basic Location if Station creation fails
                return Location(
                  id: item['id']?.toString() ?? '',
                  name: item['name']?.toString() ?? 'Unknown',
                  type: item['type']?.toString() ?? 'unknown',
                  latitude: item['location']?['latitude']?.toDouble() ?? item['latitude']?.toDouble(),
                  longitude: item['location']?['longitude']?.toDouble() ?? item['longitude']?.toDouble(),
                  address: null,
                );
              }
            } else {
              // Return a basic location for non-station items
              return Location(
                id: item['id']?.toString() ?? '',
                name: item['name']?.toString() ?? 'Unknown',
                type: item['type']?.toString() ?? 'unknown',
                latitude: item['location']?['latitude']?.toDouble() ?? item['latitude']?.toDouble(),
                longitude: item['location']?['longitude']?.toDouble() ?? item['longitude']?.toDouble(),
                address: null,
              );
            }
          }
        }).toList();
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchLocations: $e');
      rethrow;
    }
  }
}