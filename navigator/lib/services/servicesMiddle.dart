import 'package:latlong2/latlong.dart';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/services/dbApiService.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart' as myApp;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:navigator/services/geoLocator.dart';
import 'package:navigator/services/overpassApi.dart';
import 'package:navigator/models/subway_line.dart';

import '../models/journeySettings.dart';

class ServicesMiddle {
  // Singleton implementation
  static final ServicesMiddle _instance = ServicesMiddle._internal();
  factory ServicesMiddle() => _instance;
  ServicesMiddle._internal();

  dbApiService dbRest = new dbApiService();
  GeoService geoService = new GeoService();
  Overpassapi overpass = new Overpassapi();
    List<SubwayLine> loadedSubwayLines = [];
    List<List<LatLng>> get loadedPolylines => 
      loadedSubwayLines.map((line) => line.points).toList();

  Future<List<myApp.Location>> getLocations(String query) async {
    final results = await dbRest.fetchLocations(query);
    return results;
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final geo.Placemark place = placemarks.first;
        String address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].whereType<String>().join(', ');
        return address;
      } else {
        return 'No address available';
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return 'Failed to get address';
    }
  }

  Future<List<Journey>> getJourneys(myApp.Location from, myApp.Location to, DateAndTime when, bool departure, {required JourneySettings journeySettings}) async {
    final results = await dbRest.fetchJourneysByLocation(from, to, when, departure, journeySettings);
    print("Journeys fetched: ${results.length}");
    return results;
  }

  Future<Journey> refreshJourney(Journey journey) async {
    try {
      print("Refreshing journey with token: ${journey.refreshToken}");
      final refreshedJourney = await dbRest.refreshJourney(journey);
      print("Journey refreshed successfully");
      return refreshedJourney;
    } catch (e) {
      print('Error refreshing journey: $e');
      throw Exception('Failed to refresh journey: $e');
    }
  }

  Future<Journey> refreshJourneyByToken(String refreshToken) async {
    try {
      print("Refreshing journey with token: $refreshToken");
      final refreshedJourney = await dbRest.refreshJourneybyToken(refreshToken);
      print("Journey refreshed successfully");
      return refreshedJourney;
    } catch (e) {
      print('Error refreshing journey by token: $e');
      throw Exception('Failed to refresh journey by token: $e');
    }
  }

  Future<myApp.Location> getCurrentLocation() async {
    try {
      final pos = await geoService.determinePosition();
      return myApp.Location.fromPosition(pos);
    } catch (err) {
      print('Error getting Location: $err');
      return myApp.Location(type: '', id: '', name: '', latitude: 0, longitude: 0);
    }
  }
  
  Future<void> refreshPolylines() async {
    print("🔄 Starting refreshPolylines... Instance: ${this.hashCode}");

    // Get current location
    myApp.Location currentLocation = await getCurrentLocation();

    // Fetch subway lines based on user's location with 50 km radius
    loadedSubwayLines = await overpass.fetchSubwayLinesWithColors(
      lat: currentLocation.latitude,
      lon: currentLocation.longitude,
      radius: 50000 // 50 km in meters
    );

    print("Fetched ${loadedSubwayLines.length} subway lines with colors");
    print("✅ Set loadedSubwayLines to ${loadedSubwayLines.length} lines. Instance: ${this.hashCode}");
  }
}