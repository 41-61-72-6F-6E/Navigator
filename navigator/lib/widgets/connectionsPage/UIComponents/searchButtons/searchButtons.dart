import 'package:flutter/material.dart';
import 'package:navigator/models/journeySettings.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/searchButtons/searchButtonsAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';

class SearchButtons extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final ConnectionsPageUIState uiState;
  final VoidCallback onSearch;
  final void Function(TimeOfDay) onTimeChanged;
  final void Function(DateTime) onDateChanged;
  final void Function(bool) onDepartureChanged;
  final void Function(JourneySettings) onSettingsChanged;

  const SearchButtons({
    super.key,
    required this.design,
    required this.model,
    required this.uiState,
    required this.onSearch,
    required this.onTimeChanged,
    required this.onDateChanged,
    required this.onDepartureChanged,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return SearchButtonsAndroid(
          model: model,
          uiState: uiState,
          onSearch: onSearch,
          onTimeChanged: onTimeChanged,
          onDateChanged: onDateChanged,
          onDepartureChanged: onDepartureChanged,
          onSettingsChanged: onSettingsChanged,
        );
      default:
        return SearchButtonsAndroid(
          model: model,
          uiState: uiState,
          onSearch: onSearch,
          onTimeChanged: onTimeChanged,
          onDateChanged: onDateChanged,
          onDepartureChanged: onDepartureChanged,
          onSettingsChanged: onSettingsChanged,
        );
    }
  }
}