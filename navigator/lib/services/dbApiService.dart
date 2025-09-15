import 'dart:convert';
import 'dart:io';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/journeySettings.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:http/http.dart' as http;
import 'package:navigator/env/env.dart';
import 'package:navigator/models/leg.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:navigator/models/stopover.dart';
import 'package:navigator/models/trip.dart';

class DbApiService {
  // Singleton instance
  static final DbApiService _instance = DbApiService._internal();

  // Private constructor
  DbApiService._internal();

  // Public getter to access the singleton
  static DbApiService get instance => _instance;

  final String baseUrl = Env.api_url;

  String? earlierRef;
  String? laterRef;
  Location? earlierFrom;
  Location? earlierTo;

  Future<List<Journey>> fetchEarlierOrLaterJourneys(bool earlier) async
  {
    if(earlierFrom == null)
    {
      print('earlier From value is null which is not allowed when searching for earlier or later Journey');
      return [];
    }

    if(earlierTo == null)
    {
      print('earlier From value is null which is not allowed when searching for earlier or later Journey');
      return [];
    }
    final queryParams = <String, String>{};

    String buildAddress(geo.Placemark placemark) {
      final city = placemark.locality ?? '';
      final street = placemark.street ?? '';
      return city.isNotEmpty && street.isNotEmpty ? '$city, $street' : city + street;
    }

    // FROM handling
    if ((earlierFrom!.type == 'station' || earlierFrom!.type == 'stop') && (earlierFrom!.id.isNotEmpty)) {
      queryParams['from'] = earlierFrom!.id;
    } else {
      queryParams['from.latitude'] = earlierFrom!.latitude.toString();
    }
    queryParams['from.longitude'] = earlierFrom!.longitude.toString();

    try {
      final placemarks = await geo.placemarkFromCoordinates(earlierFrom!.latitude, earlierFrom!.longitude);
      if (placemarks.isNotEmpty) {
        queryParams['from.address'] = buildAddress(placemarks.first);
      }
    } catch (e) {
      print('Error getting address for from location: $e');
    }

    // TO handling
    if ((earlierTo!.type == 'station' || earlierTo!.type == 'stop') && (earlierTo!.id.isNotEmpty)) {
      queryParams['to'] = earlierTo!.id;
    } else {
      queryParams['to.latitude'] = earlierTo!.latitude.toString();
    }
    queryParams['to.longitude'] = earlierTo!.longitude.toString();

    try {
      final placemarks = await geo.placemarkFromCoordinates(earlierTo!.latitude, earlierTo!.longitude);
      if (placemarks.isNotEmpty) {
        queryParams['to.address'] = buildAddress(placemarks.first);
      }
    } catch (e) {
      print('Error getting address for to location: $e');
    }

    if(earlier)
    {
      if(earlierRef!=null)
      {
        queryParams['earlierThan'] = earlierRef!;
      }
      else
      {
        print('earlierRef is null which is not allowed when searching for earlier Journeys');
        return [];
      }
    }
    else
    {
      if(laterRef!=null)
      {
        queryParams['laterThan'] = laterRef!;
      }
      else
      {
        print('laterRef is null which is not allowed when searching for earlier Journeys');
        return [];
      }
    }

    final uri = Uri.http(baseUrl, '/journeys', queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['journeys'] == null) {
          return [];
        }

        if(earlier)
        {
          earlierRef = data['earlierRef'];
        }
        else
        {
          laterRef = data['laterRef'];
        }

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

  Future<List<Journey>> fetchJourneysByLocation(
    Location from,
    Location to,
    DateAndTime when,
    bool departure,
    JourneySettings? journeySettings,
  ) async {
    final queryParams = <String, String>{};

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

    final uri = Uri.http(baseUrl, '/journeys', queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['journeys'] == null) {
          return [];
        }

        earlierRef = data['earlierRef'];
        laterRef = data['laterRef'];
        earlierFrom = from;
        earlierTo = to;

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
    final url = 'http://$baseUrl/journeys/$encodedToken?polylines=true&stopovers=true';
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri);

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

  Future<Trip> fetchTripById(
    String tripId, {
    bool stopovers = true,
    bool remarks = true,
    bool polyline = false,
    String language = 'en',
    bool pretty = true,
  }) async {
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

    final encodedTripId = Uri.encodeComponent(tripId);

    try {
      final queryString = queryParams.entries
          .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
          .join('&');

      final url = 'http://$baseUrl/trips/$encodedTripId?$queryString';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        Map<String, dynamic> tripData;
        if (data['trip'] != null) {
          tripData = data['trip'];
        } else if (data is Map<String, dynamic>) {
          tripData = data;
        } else {
          throw FormatException('Unexpected response format: expected trip object');
        }

        Trip t = Trip.fromJson(tripData);
        t.debugPrintStopovers();
        return t;
      } else if (response.statusCode == 404) {
        throw HttpException('Trip not found or may have expired', uri: Uri.parse(url));
      } else if (response.statusCode == 500) {
        if (response.body.contains('error') || response.body.isEmpty) {
          throw HttpException('Temporary server error - trip may be unavailable', uri: Uri.parse(url));
        } else {
          throw HttpException('Server error for trip: $tripId', uri: Uri.parse(url));
        }
      } else {
        throw HttpException(
          'Failed to load trip. Status code: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception fetching trip $tripId: $e');
      rethrow;
    }
  }

  Future<Trip> fetchTripFromLeg(
    Leg leg, {
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

  Future<List<Trip>> fetchMultipleTrips(
    List<String> tripIds, {
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
      }
    }

    return trips;
  }

  Future<Journey> refreshJourney(Journey journey) async {
    final encodedToken = Uri.encodeComponent(journey.refreshToken);
    final url = 'http://$baseUrl/journeys/$encodedToken?polylines=true&stopovers=true';
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri);

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
    final uri = Uri.http(baseUrl, '/locations', {
      'poi': 'false',
      'addresses': 'true',
      'query': query,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        return (data as List)
            .where((item) =>
                item != null &&
                ((item['id'] != null && item['id'].toString().toLowerCase() != 'null') ||
                    (item['type'] != 'station' && item['latitude'] != null && item['longitude'] != null)))
            .map<Location>((item) {
          try {
            if (item['type'] == 'station' || item['type'] == 'stop') {
              return Station.fromJson(item);
            } else {
              return Location.fromJson(item);
            }
          } catch (e) {
            print('Error parsing location item: $e');
            print('Item: $item');

            if (item['type'] == 'station' || item['type'] == 'stop') {
              try {
                final location = item['location'];
                final products = item['products'];

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
                  latitude: location?['latitude']?.toDouble() ??
                      item['latitude']?.toDouble() ??
                      0.0,
                  longitude: location?['longitude']?.toDouble() ??
                      item['longitude']?.toDouble() ??
                      0.0,
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
                return Location(
                  id: item['id']?.toString() ?? '',
                  name: item['name']?.toString() ?? 'Unknown',
                  type: item['type']?.toString() ?? 'unknown',
                  latitude: item['location']?['latitude']?.toDouble() ??
                      item['latitude']?.toDouble(),
                  longitude: item['location']?['longitude']?.toDouble() ??
                      item['longitude']?.toDouble(),
                  address: null,
                );
              }
            } else {
              return Location(
                id: item['id']?.toString() ?? '',
                name: item['name']?.toString() ?? 'Unknown',
                type: item['type']?.toString() ?? 'unknown',
                latitude: item['location']?['latitude']?.toDouble() ??
                    item['latitude']?.toDouble(),
                longitude: item['location']?['longitude']?.toDouble() ??
                    item['longitude']?.toDouble(),
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
