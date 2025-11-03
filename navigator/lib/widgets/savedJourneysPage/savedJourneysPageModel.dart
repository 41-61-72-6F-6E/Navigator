import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/savedJourney.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';


/// Model class for the Saved Journeys page
/// Handles all business logic and state management
class SavedJourneysPageModel extends ChangeNotifier {
  final ServicesMiddle services;
  
  SavedJourneysPageUIState _state = const SavedJourneysPageUIState();
  
  SavedJourneysPageUIState get state => _state;
  
  SavedJourneysPageModel({required this.services});

  /// Updates the state and notifies listeners
  void _updateState(SavedJourneysPageUIState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Loads saved journeys from local storage
  Future<void> loadSavedJourneys() async {
    _updateState(_state.copyWith(isRefreshing: true));
    
    try {
      List<Savedjourney> loadedJourneys = await Localdatasaver.getSavedJourneys();
      
      // Sort by departure time
      loadedJourneys.sort((a, b) => 
        a.journey.departureTime.compareTo(b.journey.departureTime));
      
      // Split into past and future journeys
      DateTime now = DateTime.now();
      List<Savedjourney> future = [];
      List<Savedjourney> past = [];
      
      for (Savedjourney journey in loadedJourneys) {
        if (journey.journey.arrivalTime.isAfter(now)) {
          future.add(journey);
        } else {
          past.add(journey);
        }
      }
      
      // Sort past journeys in reverse (most recent first)
      past.sort((a, b) => b.journey.departureTime.compareTo(a.journey.departureTime));
      
      _updateState(_state.copyWith(
        savedJourneys: loadedJourneys,
        futureJourneys: future,
        pastJourneys: past,
        isRefreshing: false,
        isLoading: false,
      ));
      
      print('Saved journeys loaded: ${loadedJourneys.length}');
    } catch (e) {
      print('Error loading saved journeys: $e');
      _updateState(_state.copyWith(
        isRefreshing: false,
        isLoading: false,
      ));
    }
  }

  /// Refreshes specific journeys by their refresh tokens
  Future<void> refreshJourneys({bool onlyFutureJourneys = false}) async {
    List<Savedjourney> journeysToRefresh = 
      onlyFutureJourneys ? _state.futureJourneys : _state.savedJourneys;
    
    List<Savedjourney> updatedJourneys = [];
    
    for (Savedjourney sj in journeysToRefresh) {
      try {
        Journey refreshedJourney = 
          await services.refreshJourneyByToken(sj.journey.refreshToken);
        
        Savedjourney updatedJourney = Savedjourney(
          journey: refreshedJourney,
          id: Localdatasaver.calculateJourneyID(refreshedJourney),
        );
        
        updatedJourneys.add(updatedJourney);
      } catch (e) {
        print('Failed to refresh journey ${sj.id}: $e');
        // Keep the old journey if refresh fails
        updatedJourneys.add(sj);
      }
    }
    
    // Reload all journeys after refresh
    await loadSavedJourneys();
  }

  /// Refreshes a single journey by its refresh token
  Future<Journey> refreshSingleJourney(String refreshToken) async {
    return await services.refreshJourneyByToken(refreshToken);
  }

  /// Toggles between past and future journeys view
  void togglePastJourneysView() {
    _updateState(_state.copyWith(
      showingPastJourneys: !_state.showingPastJourneys,
    ));
  }

  /// Toggles between card and list view
  void toggleViewMode() {
    _updateState(_state.copyWith(cardView: !_state.cardView));
  }

  /// Updates the search query
  void updateSearchQuery(String query) {
    _updateState(_state.copyWith(searchQuery: query));
  }

  /// Toggles the expanded state of a journey group
  void toggleExpanded(int index) {
    List<bool> newExpandedList = List.from(_state.isExpandedList);
    
    // Ensure the list is the right size
    int requiredSize = _state.journeysByDate.length;
    if (newExpandedList.length < requiredSize) {
      newExpandedList.addAll(
        List<bool>.filled(requiredSize - newExpandedList.length, false)
      );
    }
    
    if (index < newExpandedList.length) {
      newExpandedList[index] = !newExpandedList[index];
      _updateState(_state.copyWith(isExpandedList: newExpandedList));
    }
  }

  /// Updates expanded list to match the number of journey groups
  void updateExpandedList() {
    int requiredSize = _state.journeysByDate.length;
    
    if (_state.isExpandedList.length != requiredSize) {
      List<bool> newExpandedList = List<bool>.filled(requiredSize, false);
      
      // Preserve existing states where possible
      for (int i = 0; i < _state.isExpandedList.length && i < requiredSize; i++) {
        newExpandedList[i] = _state.isExpandedList[i];
      }
      
      _updateState(_state.copyWith(isExpandedList: newExpandedList));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}