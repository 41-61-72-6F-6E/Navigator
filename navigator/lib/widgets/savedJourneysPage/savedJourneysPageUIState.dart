import 'package:navigator/models/savedJourney.dart';

/// Represents the UI state for the Saved Journeys page
class SavedJourneysPageUIState {
  final List<Savedjourney> savedJourneys;
  final List<Savedjourney> pastJourneys;
  final List<Savedjourney> futureJourneys;
  final List<bool> isExpandedList;
  final bool isLoading;
  final bool isRefreshing;
  final bool showingPastJourneys;
  final bool cardView;
  final String searchQuery;
  
  const SavedJourneysPageUIState({
    this.savedJourneys = const [],
    this.pastJourneys = const [],
    this.futureJourneys = const [],
    this.isExpandedList = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.showingPastJourneys = false,
    this.cardView = true,
    this.searchQuery = '',
  });

  SavedJourneysPageUIState copyWith({
    List<Savedjourney>? savedJourneys,
    List<Savedjourney>? pastJourneys,
    List<Savedjourney>? futureJourneys,
    List<bool>? isExpandedList,
    bool? isLoading,
    bool? isRefreshing,
    bool? showingPastJourneys,
    bool? cardView,
    String? searchQuery,
  }) {
    return SavedJourneysPageUIState(
      savedJourneys: savedJourneys ?? this.savedJourneys,
      pastJourneys: pastJourneys ?? this.pastJourneys,
      futureJourneys: futureJourneys ?? this.futureJourneys,
      isExpandedList: isExpandedList ?? this.isExpandedList,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      showingPastJourneys: showingPastJourneys ?? this.showingPastJourneys,
      cardView: cardView ?? this.cardView,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Returns the journeys that should be displayed based on current view mode
  List<Savedjourney> get displayedJourneys {
    return showingPastJourneys ? pastJourneys : futureJourneys;
  }

  /// Returns journeys grouped by date for the current view
  List<List<Savedjourney>> get journeysByDate {
    List<Savedjourney> journeys = List.from(displayedJourneys);
    
    // Remove the first future journey if showing future journeys (it's shown separately)
    if (!showingPastJourneys && journeys.isNotEmpty) {
      journeys.removeAt(0);
    }
    
    if (journeys.isEmpty) return [];
    
    List<List<Savedjourney>> grouped = [];
    
    for (int i = 0; i < journeys.length; i++) {
      if (i == 0) {
        grouped.add([journeys[i]]);
      } else {
        DateTime previous = journeys[i - 1].journey.plannedDepartureTime;
        DateTime current = journeys[i].journey.plannedDepartureTime;
        
        if (current.day == previous.day &&
            current.month == previous.month &&
            current.year == previous.year) {
          grouped.last.add(journeys[i]);
        } else {
          grouped.add([journeys[i]]);
        }
      }
    }
    
    return grouped;
  }

  /// Returns the next upcoming journey, if any
  Savedjourney? get nextJourney {
    return futureJourneys.isNotEmpty ? futureJourneys.first : null;
  }

  /// Checks if the next journey is currently ongoing
  bool get isNextJourneyOngoing {
    if (nextJourney == null) return false;
    
    DateTime now = DateTime.now();
    return now.isAfter(nextJourney!.journey.plannedDepartureTime) &&
           now.isBefore(nextJourney!.journey.arrivalTime);
  }
}