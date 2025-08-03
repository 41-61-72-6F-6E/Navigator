import 'dart:convert';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Localdatasaver {
  static const String favesListKey = 'favesList';
  static const String savedJourneysKey = 'savedJourneys';

  static Future<void> addLocationToFavourites(Location location, String name) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> favesJson = prefs.getStringList(favesListKey) ?? [];
      
      FavoriteLocation favorite = FavoriteLocation(name: name, location: location);
      favesJson.add(jsonEncode(favorite.toJson()));
      await prefs.setStringList(favesListKey, favesJson);
    } catch (e) {
      print('Error saving to preferences: $e');
    }
  }

  static Future<void> removeFavouriteLocation(FavoriteLocation l) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<FavoriteLocation> faves = await getFavouriteLocations();
    faves.removeWhere((fave) => fave.location.id == l.location.id);
    List<String> favesJson = [];
    for(FavoriteLocation lo in faves)
    {
      favesJson.add(jsonEncode(lo));
    }
    prefs.setStringList(favesListKey, favesJson);
  }
 
  static Future<List<FavoriteLocation>> getFavouriteLocations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> favesJson = prefs.getStringList(favesListKey) ?? [];
      List<FavoriteLocation> faves = [];
      
      for(String s in favesJson) {
        Map<String, dynamic> json = jsonDecode(s);
        
        // Handle both old format (just location) and new format (FavoriteLocation)
        if (json.containsKey('name') && json.containsKey('location')) {
          faves.add(FavoriteLocation.fromJson(json));
        } else {
          // Old format - create FavoriteLocation with default name
          faves.add(FavoriteLocation(
            name: 'Unnamed Location',
            location: Location.fromJson(json),
          ));
        }
      }
      return faves;
    } catch (e) {
      print('Error loading from preferences: $e');
      return [];
    }
  }

  static Future<void> saveJourney(String refreshToken) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedJourneys = prefs.getStringList(savedJourneysKey) ?? [];
      savedJourneys.add(refreshToken);
      await prefs.setStringList(savedJourneysKey, savedJourneys);
    }
    catch (e) {
      print('Error saving journey: $e');
    }
  }

  static Future<void> removeSavedJourney(String refreshToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedJourneys = prefs.getStringList(savedJourneysKey) ?? [];
    savedJourneys.remove(refreshToken);
    prefs.setStringList(savedJourneysKey, savedJourneys);
  }

  static Future<List<String>> getSavedJourneyRefreshTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(savedJourneysKey) ?? [];
  }

}

