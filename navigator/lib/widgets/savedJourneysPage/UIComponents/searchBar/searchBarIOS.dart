import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class SearchBarIOS extends StatefulWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;

  const SearchBarIOS({
    super.key,
    required this.state,
    required this.model,
  });

  @override
  State<SearchBarIOS> createState() => _SearchBarIOSState();
}

class _SearchBarIOSState extends State<SearchBarIOS> {
  final TextEditingController _searchController = TextEditingController();
  bool _showingSuggestions = false;
  List<dynamic> _filteredJourneys = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    setState(() {
      _showingSuggestions = query.isNotEmpty;
      
      if (query.isEmpty) {
        _filteredJourneys = [];
        return;
      }

      final journeys = widget.state.showingPastJourneys 
          ? widget.state.pastJourneys 
          : widget.state.futureJourneys;
      
      _filteredJourneys = journeys.where((journey) {
        final origin = journey.journey.legs.first.origin.name.toLowerCase();
        final destination = journey.journey.legs.last.destination.name.toLowerCase();
        return origin.contains(query.toLowerCase()) || 
               destination.contains(query.toLowerCase());
      }).take(5).toList();
    });
  }

  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.model.togglePastJourneysView();
            },
            child: Text(
              widget.state.showingPastJourneys
                  ? 'Show Future Journeys'
                  : 'Show Past Journeys',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Settings action
            },
            child: const Text('Settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search saved journeys',
                  onChanged: _updateSearch,
                  onSubmitted: (value) {
                    widget.model.updateSearchQuery(value);
                  },
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                onPressed: () {
                  // Filter functionality
                },
                child: const Icon(CupertinoIcons.slider_horizontal_3),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                onPressed: () => widget.model.toggleViewMode(),
                child: Icon(
                  widget.state.cardView 
                      ? CupertinoIcons.list_bullet 
                      : CupertinoIcons.square_grid_2x2,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                onPressed: _showActionSheet,
                child: const Icon(CupertinoIcons.ellipsis),
              ),
            ],
          ),
        ),
        if (_showingSuggestions && _filteredJourneys.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredJourneys.length,
              separatorBuilder: (context, index) => Divider(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              itemBuilder: (context, index) {
                final journey = _filteredJourneys[index];
                final origin = journey.journey.legs.first.origin.name;
                final destination = journey.journey.legs.last.destination.name;
                final displayText = '$origin → $destination';
                
                return CupertinoListTile(
                  leading: const Icon(CupertinoIcons.train_style_one),
                  title: Text(displayText),
                  subtitle: Text(
                    journey.journey.departureTime.toString().substring(0, 16),
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  onTap: () {
                    _searchController.text = displayText;
                    widget.model.updateSearchQuery(_searchController.text);
                    setState(() {
                      _showingSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}