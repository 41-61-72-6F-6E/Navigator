import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/services/dbApiService.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart' as myApp;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:navigator/services/geoLocator.dart';
import 'package:navigator/services/overpassApi.dart';
import 'package:navigator/models/subway_line.dart';
import 'package:navigator/models/trip.dart'; // Add this import
import 'package:navigator/models/leg.dart';   // Add this import

import '../models/journeySettings.dart';

class ServicesMiddle {
  // Singleton implementation
  static final ServicesMiddle _instance = ServicesMiddle._internal();
  factory ServicesMiddle() => _instance;
  ServicesMiddle._internal();

  dbApiService dbRest = dbApiService();
  GeoService geoService = GeoService();
  Overpassapi overpass = Overpassapi();
  List<SubwayLine> loadedSubwayLines = [];
  List<List<LatLng>> get loadedPolylines => 
    loadedSubwayLines.map((line) => line.points).toList();

  // Existing methods...
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
    return results;
  }

  Future<Journey> refreshJourney(Journey journey) async {
    try {
      final refreshedJourney = await dbRest.refreshJourney(journey);
      return refreshedJourney;
    } catch (e) {
      print('Error refreshing journey: $e');
      throw Exception('Failed to refresh journey: $e');
    }
  }

  Future<Journey> refreshJourneyByToken(String refreshToken) async {
    try {
      final refreshedJourney = await dbRest.refreshJourneybyToken(refreshToken);
      return refreshedJourney;
    } catch (e) {
      print('Error refreshing journey by token: $e');
      throw Exception('Failed to refresh journey by token: $e');
    }
  }

  // NEW TRIP METHODS
  
  /// Fetches detailed trip information by trip ID
  /// [tripId] - The unique identifier for the trip
  /// [includePolyline] - Whether to include geographic shape data
  /// [includeRemarks] - Whether to include hints and warnings
  Future<Trip> getTripById(String tripId, {
    bool includePolyline = false,
    bool includeRemarks = true,
  }) async {
    try {
      print("🚂 Fetching trip details for ID: $tripId");
      final trip = await dbRest.fetchTripById(
        tripId,
        stopovers: true,
        remarks: includeRemarks,
        polyline: includePolyline,
      );
      print("✅ Trip fetched successfully: ${trip.line?.name ?? 'Unknown'}");
      return trip;
    } catch (e) {
      print('❌ Error fetching trip by ID: $e');
      throw Exception('Failed to fetch trip: $e');
    }
  }

  /// Fetches trip details from a journey leg
  /// [leg] - The journey leg containing the trip ID
  /// [includePolyline] - Whether to include geographic shape data
  /// [includeRemarks] - Whether to include hints and warnings
  Future<Trip?> getTripFromLeg(Leg leg, {
  bool includePolyline = false,
  bool includeRemarks = true,
}) async {
  try {
    // Skip walking legs
    if (leg.isWalking == true) {
      print("DEBUG: Skipping walking leg from ${leg.origin.name} to ${leg.destination.name}");
      return null;
    }

    // Check if leg has a trip ID
    if (leg.tripID == null || leg.tripID!.isEmpty) {
      print("DEBUG: Leg has no trip ID: ${leg.lineName ?? 'Unknown'} from ${leg.origin.name} to ${leg.destination.name}");
      return null;
    }

    print("DEBUG: Fetching trip from leg: ${leg.lineName ?? 'Unknown'} (tripID: ${leg.tripID})");
    
    final trip = await dbRest.fetchTripFromLeg(
      leg,
      stopovers: true,
      remarks: includeRemarks,
      polyline: includePolyline,
    );
    
    print("DEBUG: Successfully fetched trip: ${trip.line?.name ?? 'Unknown'}");
    print("DEBUG: Trip has ${trip.stopovers.length} stopovers");
    
    return trip;
  } on HttpException catch (e) {
    if (e.message.contains('not found') || e.message.contains('expired')) {
      print('INFO: Trip not available for leg ${leg.lineName}: ${e.message}');
      return null; // Gracefully handle missing trips
    } else if (e.message.contains('Temporary server error')) {
      print('WARN: Temporary error for trip ${leg.tripID}: ${e.message}');
      // You might want to retry here or return null
      return null;
    } else {
      print('ERROR: HTTP error fetching trip from leg: $e');
      return null; // Don't crash the entire operation
    }
  } catch (e) {
    print('ERROR: Unexpected error fetching trip from leg: $e');
    print('DEBUG: Leg details - tripID: ${leg.tripID}, lineName: ${leg.lineName}, product: ${leg.product}');
    return null;
  }
}

  /// Fetches multiple trips from a list of journey legs
  /// [legs] - List of journey legs to fetch trips for
  /// [includePolyline] - Whether to include geographic shape data
  /// [includeRemarks] - Whether to include hints and warnings
  Future<List<Trip>> getTripsFromLegs(List<Leg> legs, {
    bool includePolyline = false,
    bool includeRemarks = true,
  }) async {
    List<Trip> trips = [];
    
    print("🚂 Fetching trips from ${legs.length} legs");
    
    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i];
      print("Processing leg ${i + 1}/${legs.length}: ${leg.lineName ?? 'Walking'}");
      
      final trip = await getTripFromLeg(
        leg,
        includePolyline: includePolyline,
        includeRemarks: includeRemarks,
      );
      
      if (trip != null) {
        trips.add(trip);
      }
    }
    
    print("✅ Successfully fetched ${trips.length} trips from ${legs.length} legs");
    return trips;
  }

  /// Fetches trips for an entire journey
  /// [journey] - The journey to fetch trips for
  /// [includePolyline] - Whether to include geographic shape data
  /// [includeRemarks] - Whether to include hints and warnings
  Future<List<Trip>> getTripsFromJourney(Journey journey, {
    bool includePolyline = false,
    bool includeRemarks = true,
  }) async {
    try {
      print("🚂 Fetching trips for journey with ${journey.legs.length} legs");
      return await getTripsFromLegs(
        journey.legs,
        includePolyline: includePolyline,
        includeRemarks: includeRemarks,
      );
    } catch (e) {
      print('❌ Error fetching trips from journey: $e');
      throw Exception('Failed to fetch trips from journey: $e');
    }
  }

  /// Batch fetch multiple trips by their IDs
  /// [tripIds] - List of trip IDs to fetch
  /// [includePolyline] - Whether to include geographic shape data
  /// [includeRemarks] - Whether to include hints and warnings
  Future<List<Trip>> getMultipleTrips(List<String> tripIds, {
    bool includePolyline = false,
    bool includeRemarks = true,
  }) async {
    try {
      print("🚂 Batch fetching ${tripIds.length} trips");
      final trips = await dbRest.fetchMultipleTrips(
        tripIds,
        stopovers: true,
        remarks: includeRemarks,
        polyline: includePolyline,
      );
      print("✅ Successfully fetched ${trips.length}/${tripIds.length} trips");
      return trips;
    } catch (e) {
      print('❌ Error batch fetching trips: $e');
      throw Exception('Failed to fetch multiple trips: $e');
    }
  }

  // Existing methods continue...
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
    // Get current location
    myApp.Location currentLocation = await getCurrentLocation();

    // Fetch subway lines based on user's location with 50 km radius
    loadedSubwayLines = await overpass.fetchSubwayLinesWithColors(
      lat: currentLocation.latitude,
      lon: currentLocation.longitude,
      radius: 50000 // 50 km in meters
    );
  }
}