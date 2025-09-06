import 'dart:convert';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Localdatasaver {
  static const String favesListKey = 'favesList';
  static const String savedJourneysKeyDeprecated = 'savedJourneys';
  static const String savedJourneysKeyNew = 'savedJourneysKeyNew';

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

  static Future<void> saveJourney(Journey journey) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Savedjourney> journeys = await getSavedJourneys(); 
      Savedjourney j = Savedjourney(journey: journey, id: calculateJourneyID(journey));
      journeys.add(j);
      List<String> savedJourneysJson = [];
      for(Savedjourney sj in journeys)
      {
        savedJourneysJson.add(jsonEncode(sj));
      }
      await prefs.setStringList(savedJourneysKeyNew, savedJourneysJson);
    }
    catch (e) {
      print('Error saving journey: $e');
    }
  }

  static Future<void> removeSavedJourney(Journey journey) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> savedJourneysJson = prefs.getStringList(savedJourneysKeyNew) ?? [];
  List<Savedjourney> savedJourneys = [];
  for(String s in savedJourneysJson)
  {
    savedJourneys.add(Savedjourney.fromJson(jsonDecode(s))); // ← Added fromJson()
  }
  String id = calculateJourneyID(journey);
  savedJourneys.removeWhere((sj) => sj.id == id);
  List<String> savedJourneysJsonNew = [];
  for(Savedjourney sj in savedJourneys)
  {
    savedJourneysJsonNew.add(jsonEncode(sj));
  }
  prefs.setStringList(savedJourneysKeyNew, savedJourneysJsonNew);
}

  static Future<List<Savedjourney>> getSavedJourneys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedJourneysJson = prefs.getStringList(savedJourneysKeyNew) ?? [];
    List<Savedjourney> journeys = [];
    for(String s in savedJourneysJson)
    {
      journeys.add(Savedjourney.fromJson(jsonDecode(s)));
    }
    return journeys;
  }

  static Future<bool> journeyIsSaved(Journey journey) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedJourneysJson = prefs.getStringList(savedJourneysKeyNew) ?? [];
    List<Savedjourney> journeys = [];
    for(String s in savedJourneysJson)
    {
      journeys.add(Savedjourney.fromJson(jsonDecode(s)));
    }
    Savedjourney check = Savedjourney(journey: journey, id: calculateJourneyID(journey));
    for(Savedjourney sj in journeys)
    {
      if(sj.id == check.id)
      {
        return true;
      }
    }
    return false;
  }

  static String calculateJourneyID(Journey j)
  {
    String id = '';
    for(Leg l in j.legs)
    {
      String newId = '${id}${l.origin.name}${l.plannedDeparture}${l.destination.name}${l.plannedArrival.toString()}';
      id = newId; 
    }
    return id;
  }

}

