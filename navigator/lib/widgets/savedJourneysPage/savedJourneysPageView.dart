import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/journeysList/journeysListWidget.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/nextJourney/nextJourney.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/searchBar/searchBar.dart' as mysearchbar;

/// View class for the Saved Journeys page
/// Handles all UI rendering and user interactions
class SavedJourneysPageView extends StatefulWidget {
  final SavedJourneysPageModel model;
  final int design;

  const SavedJourneysPageView({
    super.key,
    required this.model,
    required this.design,
  });

  @override
  State<SavedJourneysPageView> createState() => _SavedJourneysPageViewState();
}

class _SavedJourneysPageViewState extends State<SavedJourneysPageView> {
  late Color successColor;
  late Color onSuccessColor;
  late Color successIconColor;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
    widget.model.loadSavedJourneys();
//    _updateColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateColors();
  }

  void _updateColors() {
    Brightness brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      successColor = const Color(0xFF1C2717);
      onSuccessColor = const Color.fromARGB(255, 195, 230, 183);
      successIconColor = const Color.fromARGB(255, 91, 128, 77);
    } else {
      successColor = const Color.fromARGB(255, 195, 230, 183);
      onSuccessColor = const Color(0xFF1C2717);
      successIconColor = const Color.fromARGB(255, 91, 128, 77);
    }
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {
        widget.model.updateExpandedList();
      });
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSavedJourneysPage(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedJourneysPage(BuildContext context) {
    final state = widget.model.state;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        mysearchbar.SearchBar(design: widget.design, state: state, model: widget.model),       
        if (state.nextJourney != null && !state.showingPastJourneys)
          nextJourney(design: widget.design, state: state, model: widget.model, successColor: successColor, onSuccessColor: onSuccessColor,),
        if (state.showingPastJourneys && state.pastJourneys.isNotEmpty)
          Center(
            child: Text(
              'Past Journeys',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        if (state.showingPastJourneys)
          Expanded(child: journeysListWidget(design: widget.design, state: state, model: widget.model, successColor: successColor, onSuccessColor: onSuccessColor, journeysList: state.pastJourneys)),
        if (!state.showingPastJourneys)
          Expanded(child: journeysListWidget(design: widget.design, state: state, model: widget.model, successColor: successColor, onSuccessColor: onSuccessColor, journeysList: state.futureJourneys)),
        const SizedBox(height: 8),
      ],
    );
  }
}