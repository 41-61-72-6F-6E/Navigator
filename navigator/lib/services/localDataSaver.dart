import 'dart:convert';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Localdatasaver {
  static const String favesListKey = 'favesList';
 
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
}