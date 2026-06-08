import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';

class FavesNotifier extends ChangeNotifier {
  List<FavoriteLocation> faves;
  List<Location> searchResults;
  String lastSearchedText;

  FavesNotifier({
    this.faves = const [],
    this.searchResults = const [],
    this.lastSearchedText = '',
  });

  void updateFaves(List<FavoriteLocation> faves) {
    this.faves = faves;
    notifyListeners();
  }

  void updateSearchResults(List<Location> results) {
    searchResults = results;
    notifyListeners();
  }

  void clearSearch() {
    searchResults = [];
    lastSearchedText = '';
    notifyListeners();
  }

  void setLastSearchedText(String text) {
    lastSearchedText = text;
    // No notifyListeners — this is internal bookkeeping only
  }
}