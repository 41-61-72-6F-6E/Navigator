import 'package:flutter/material.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/searchBar/searchBarAndroid.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/searchBar/searchBarIOS.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class SearchBar extends StatelessWidget {
  final int design;
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;

  const SearchBar({
    super.key,
    required this.design,
    required this.state,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return SearchBarAndroid(state: state, model: model);
      case 1: 
        return SearchBarIOS(state: state, model: model);
      // Future designs can be added here
      default:
        return SearchBarAndroid(state: state, model: model);
    }
  }
}