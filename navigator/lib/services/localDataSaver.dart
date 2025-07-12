import 'dart:convert';

import 'package:navigator/models/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Localdatasaver 
{

  final String favesListKey = 'favesList';

  void addLocationToFavourites(Location l) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favesJson = prefs.getStringList(favesListKey) ?? [];
    favesJson.add(jsonEncode(l.toJson()));
    prefs.setStringList(favesListKey, favesJson);
  }

  Future<List<Location>> getFavouriteLocations() async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favesJson = prefs.getStringList(favesListKey) ?? [];
    List<Location> faves = [];
    for(String s in favesJson)
    {
      faves.add(Location.fromJson(jsonDecode(s)));
    }
    return faves;
  }

}