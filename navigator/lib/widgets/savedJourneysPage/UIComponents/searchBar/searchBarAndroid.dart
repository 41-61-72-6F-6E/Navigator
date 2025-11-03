import 'package:flutter/material.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class SearchBarAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;

  const SearchBarAndroid({
    super.key,
    required this.state,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {    
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          elevation: WidgetStateProperty.all(0),
          controller: controller,
          hintText: 'Search saved journeys',
          trailing: <Widget>[
            Tooltip(
              message: "Filter your search",
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Implement filter functionality here
                },
              ),
            ),
            if (state.cardView)
              Tooltip(
                message: "Switch to list view",
                child: IconButton(
                  onPressed: () => model.toggleViewMode(),
                  icon: const Icon(Icons.list),
                ),
              ),
            if (!state.cardView)
              Tooltip(
                message: "Switch to card view",
                child: IconButton(
                  onPressed: () => model.toggleViewMode(),
                  icon: const Icon(Icons.view_agenda_outlined),
                ),
              ),
            MenuAnchor(
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return Tooltip(
                  message: 'More Options',
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      controller.open();
                    },
                  ),
                );
              },
              menuChildren: [
                MenuItemButton(
                  onPressed: () => model.togglePastJourneysView(),
                  child: Text(
                    state.showingPastJourneys
                        ? 'Show Future Journeys'
                        : 'Show Past Journeys',
                  ),
                ),
                MenuItemButton(
                  onPressed: () {},
                  child: const Text('Settings'),
                ),
              ],
            ),
          ],
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        // Filter journeys based on search query
        final query = controller.text.toLowerCase();
        
        // Get the appropriate journeys list
        final journeys = state.showingPastJourneys 
            ? state.pastJourneys 
            : state.futureJourneys;
        
        // Filter journeys that match the search query
        final filteredJourneys = journeys.where((journey) {
          // Search in origin and destination names
          final origin = journey.journey.legs.first.origin.name.toLowerCase();
          final destination = journey.journey.legs.last.destination.name.toLowerCase();
          return origin.contains(query) || destination.contains(query);
        }).toList();
        
        // Return search suggestions
        return filteredJourneys.take(5).map((journey) {
          final origin = journey.journey.legs.first.origin.name;
          final destination = journey.journey.legs.last.destination.name;
          final displayText = '$origin → $destination';
          
          return ListTile(
            leading: const Icon(Icons.train),
            title: Text(displayText),
            subtitle: Text(
              journey.journey.departureTime.toString().substring(0, 16),
            ),
            onTap: () {
              // Update the search query in the model
              model.updateSearchQuery(controller.text);
              controller.closeView(displayText);
            },
          );
        }).toList();
      },
    );
  }
}