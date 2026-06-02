import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/journeySettings.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/favesRow/favesRow.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/inputFields/inputFields.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/journeyList/journeyList.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/searchButtons/searchButtons.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/searchResults/searchResults.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/favouriteButton/favouriteButton.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';

/// Pure view layer.  Receives everything it needs via constructor parameters
/// and callbacks – it never reads or mutates state directly.
class ConnectionsPageView {
  // ── Constructor ───────────────────────────────────────────────────────────

  const ConnectionsPageView({
    required this.model,
    required this.uiState,
    required this.fromController,
    required this.toController,
    required this.fromFocusNode,
    required this.toFocusNode,
    required this.scrollController,
    required this.onFromLocationTap,
    required this.onToLocationTap,
    required this.onSwitch,
    required this.onStationSelected,
    required this.onLocationSelected,
    required this.onSearch,
    required this.onAddEarlier,
    required this.onAddLater,
    required this.onJourneyTap,
    required this.onTimeChanged,
    required this.onDateChanged,
    required this.onDepartureChanged,
    required this.onSettingsChanged,
    required this.onFaveChipTap,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
    required this.onResetToNow,
  });

  // ── Injected state (read-only references) ─────────────────────────────────
  final ConnectionsPageModel model;
  final ConnectionsPageUIState uiState;

  // ── Controllers / nodes ───────────────────────────────────────────────────
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocusNode;
  final FocusNode toFocusNode;
  final ScrollController? scrollController;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  final VoidCallback onFromLocationTap;
  final VoidCallback onToLocationTap;
  final VoidCallback onSwitch;
  final void Function(Station, bool searchingFrom) onStationSelected;
  final void Function(Location, bool searchingFrom) onLocationSelected;
  final VoidCallback onSearch;
  final VoidCallback onAddEarlier;
  final VoidCallback onAddLater;
  final void Function(Journey) onJourneyTap;
  final void Function(TimeOfDay) onTimeChanged;
  final void Function(DateTime) onDateChanged;
  final void Function(bool) onDepartureChanged;
  final void Function(JourneySettings) onSettingsChanged;
  final void Function(FavoriteLocation, bool searchingFrom) onFaveChipTap;
  final void Function(Location) onAddFavourite;
  final void Function(FavoriteLocation) onRemoveFavourite;
  final VoidCallback onResetToNow;

  // ═══════════════════════════════════════════════════════════════════════════
  // Public build entry-points
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildInputFields(BuildContext context) {
    return InputFields(
      design: 0,
      model: model,
      uiState: uiState,
      fromController: fromController,
      toController: toController,
      fromFocusNode: fromFocusNode,
      toFocusNode: toFocusNode,
      onFromLocationTap: onFromLocationTap,
      onToLocationTap: onToLocationTap,
      onSwitch: onSwitch,
    );
  }

  Widget buildFaves(BuildContext context, bool searchingFrom) {
    return FavesRow(
      design: 0,
      model: model,
      searchingFrom: searchingFrom,
      onFaveChipTap: onFaveChipTap,
    );
  }

  Widget buildSearchResults(BuildContext context, bool searchingFrom) {
    return SearchResults(
      design: 0,
      model: model,
      searchingFrom: searchingFrom,
      onStationSelected: onStationSelected,
      onLocationSelected: onLocationSelected,
      onAddFavourite: onAddFavourite,
      onRemoveFavourite: onRemoveFavourite,
    );
  }

  Widget buildJourneys(BuildContext context) {
    return JourneyList(
      design: 0,
      model: model,
      scrollController: scrollController,
      shouldAutoScrollToTop: uiState.shouldAutoScrollToTop,
      onAddEarlier: onAddEarlier,
      onAddLater: onAddLater,
      onResetToNow: onResetToNow,
      onJourneyTap: onJourneyTap,
    );
  }

  Widget buildButtons(BuildContext context) {
    return SearchButtons(
      design: 0,
      model: model,
      uiState: uiState,
      onSearch: onSearch,
      onTimeChanged: onTimeChanged,
      onDateChanged: onDateChanged,
      onDepartureChanged: onDepartureChanged,
      onSettingsChanged: onSettingsChanged,
    );
  }

  Widget buildFavouriteButton(BuildContext context, Location location) {
    return FavouriteButton(
      design: 0,
      model: model,
      location: location,
      onAddFavourite: onAddFavourite,
      onRemoveFavourite: onRemoveFavourite,
    );
  }
}