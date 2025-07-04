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
              return Station.fromJson(item);
            } else {
              return Location.fromJson(item);
            }
          } catch (e) {
            print('Error parsing location item: $e');
            print('Item: $item');
            // Return a basic location to avoid breaking the entire list
            return Location(
              id: item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'Unknown',
              type: item['type']?.toString() ?? 'unknown',
              latitude: item['location']?['latitude']?.toDouble() ?? item['latitude']?.toDouble(),
              longitude: item['location']?['longitude']?.toDouble() ?? item['longitude']?.toDouble(),
              address: null,
            );
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