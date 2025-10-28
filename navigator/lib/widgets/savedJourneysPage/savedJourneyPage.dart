import 'package:flutter/material.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageView.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';

/// Main page widget for Saved Journeys
/// Creates the model and passes it to the view
class SavedjourneysPage extends StatefulWidget {
  final int design;
  final ServicesMiddle services;

  SavedjourneysPage({
    super.key,
    this.design = 0,
    ServicesMiddle? services,
  }) : services = services ?? ServicesMiddle();

  @override
  SavedjourneysPageState createState() => SavedjourneysPageState();
}

class SavedjourneysPageState extends State<SavedjourneysPage> {
  late SavedJourneysPageModel _model;

  @override
  void initState() {
    super.initState();
    _model = SavedJourneysPageModel(services: widget.services);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void reloadPage() {
    print('reloaded');
    _model.loadSavedJourneys();
  }

  @override
  Widget build(BuildContext context) {
    // For now, only Android implementation is refactored
    // Other platforms can be added later following the same pattern
    return SavedJourneysPageView(model: _model, design: widget.design);
  }
}