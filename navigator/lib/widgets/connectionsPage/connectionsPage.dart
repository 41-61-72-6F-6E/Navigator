import 'dart:async';

import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/models/dateAndTime.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUp.dart';
import 'package:navigator/widgets/journeyPage/journeyPage.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageView.dart';

class ConnectionsPage extends StatefulWidget {
  final ConnectionsPageIni page;

  const ConnectionsPage(this.page, {super.key});

  @override
  State<ConnectionsPage> createState() =>
      _ConnectionsPageState();
}

class _ConnectionsPageState
    extends State<ConnectionsPage> {
  // ── Layer instances ───────────────────────────────────────────────────────
  final ConnectionsPageModel _model = ConnectionsPageModel();
  final ConnectionsPageUIState _uiState = ConnectionsPageUIState();

  // ── Controllers / nodes ───────────────────────────────────────────────────
  late final TextEditingController _toController;
  late final TextEditingController _fromController;
  late final FocusNode _fromFocusNode;
  late final FocusNode _toFocusNode;
  ScrollController? _scrollController;

  // ── Search debounce ───────────────────────────────────────────────────────
  Timer? _debounce;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
void initState() {
  super.initState();
  _model.page = widget.page;

  _fromFocusNode = FocusNode();
  _toFocusNode = FocusNode();
  _toController = TextEditingController(text: '');
  _fromController = TextEditingController(text: '');
  _scrollController = ScrollController();

  _fromFocusNode.addListener(() {
    if (!_fromFocusNode.hasFocus) {
      setState(() {
        _model.searchResultsFrom.clear();
        _uiState.searching = false;
      });
    }
    if (_fromFocusNode.hasFocus) {
      setState(() {
        _uiState.searching = true;
        _uiState.searchingFrom = true;
      });
    }
  });

  _toFocusNode.addListener(() {
    if (!_toFocusNode.hasFocus) {
      setState(() {
        _model.searchResultsTo.clear();
        _uiState.searching = false;
      });
    }
    if (_toFocusNode.hasFocus) {
      setState(() {
        _uiState.searching = true;
        _uiState.searchingFrom = false;
      });
    }
  });

  _toController.addListener(
      () => _onSearchChanged(_toController.text.trim(), false));
  _fromController.addListener(
      () => _onSearchChanged(_fromController.text.trim(), true));

  _getFaves();
  if(widget.page.from.id == '')
  {
    _updateLocationWithCurrentPosition(true, true);
  }
  else
  {
    _updateLocationWithCurrentPosition(false, true);
  }
}



  @override
  void dispose() {
    _debounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  // ── Search helpers ────────────────────────────────────────────────────────

  void _onSearchChanged(String query, bool from) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query != _model.lastSearchedText) {
        _getSearchResults(query, from);
        _model.lastSearchedText = query;
      }
    });
  }

  // ── Async → setState bridges ──────────────────────────────────────────────

  Future<void> _updateLocationWithCurrentPosition(
      bool from, bool startSearchWhenFinished) async {
    try {
      Location l = await _model.fetchCurrentLocation();
      setState(() {
        if (from) {
          widget.page.from = l;
          _toController.text = widget.page.to.name;
          _fromController.text = 'Current Location';
        } else {
          widget.page.to = l;
          _toController.text = 'Current Location';
          _fromController.text = widget.page.from.name;
        }
      });
      if (startSearchWhenFinished) _search();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getSearchResults(String query, bool from) async {
    final results = await _model.fetchSearchResults(query);
    setState(() {
      if (from) {
        _model.searchResultsFrom = results;
      } else {
        _model.searchResultsTo = results;
      }
    });
  }

  Future<void> _getFaves() async {
    await _model.loadFavourites();
    setState(() {});
  }

  Future<void> _addEarlierJourneys() async {
    setState(() {
      _uiState.inJourneySearchAnimation = true;
      _uiState.shouldAutoScrollToTop = true;
    });
    try {
      final journeys = await _model.fetchEarlierJourneys();
      if (journeys.isEmpty) print('no earlier Journeys found');
      setState(() {
        _model.currentJourneys!.addAll(journeys);
        _model.currentJourneys!.sort(_model.departure
            ? (a, b) => a.departureTime.compareTo(b.departureTime)
            : (a, b) => a.arrivalTime.compareTo(b.arrivalTime));
        _uiState.inJourneySearchAnimation = false;
      });
    } catch (e) {
      print('Error adding earlier Journeys $e');
      setState(() => _uiState.inJourneySearchAnimation = false);
    }
  }

  Future<void> _addLaterJourneys() async {
    setState(() {
      _uiState.inJourneySearchAnimation = true;
      _uiState.shouldAutoScrollToTop = false;
    });
    try {
      final journeys = await _model.fetchLaterJourneys();
      if (journeys.isEmpty) print('no later Journeys found');
      setState(() {
        _model.currentJourneys!.addAll(journeys);
        _model.currentJourneys!.sort(_model.departure
            ? (a, b) => a.departureTime.compareTo(b.departureTime)
            : (a, b) => a.arrivalTime.compareTo(b.arrivalTime));
        _uiState.inJourneySearchAnimation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController?.hasClients == true) {
          _scrollController!.animateTo(
            _scrollController!.position.maxScrollExtent,
            duration: Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      print('Error adding later Journeys $e');
      setState(() => _uiState.inJourneySearchAnimation = false);
    }
  }

  Future<void> _getJourneys() async {
    try {
      final from = Location(
        backend: "dbRest",
        id: widget.page.from.id,
        latitude: widget.page.from.latitude,
        longitude: widget.page.from.longitude,
        name: widget.page.from.name,
        type: widget.page.from.type,
        address: null,
      );
      final to = Location(
        backend: "dbRest",
        id: widget.page.to.id,
        latitude: widget.page.to.latitude,
        longitude: widget.page.to.longitude,
        name: widget.page.to.name,
        type: widget.page.to.type,
        address: null,
      );

      final journeys = await _model.fetchJourneys(
        from,
        to,
        DateAndTime.fromDateTimeAndTime(
            _model.selectedDate, _model.selectedTime),
        _model.departure,
      );

      print('Received ${journeys.length} journeys');
      setState(() {
        _model.currentJourneys = journeys;
        _uiState.inJourneySearchAnimation = false;
      });
    } catch (e) {
      print('Error getting journeys: $e');
      setState(() {
        _model.currentJourneys = [];
        _uiState.inJourneySearchAnimation = false;
      });
    }
  }

  // ── Event handlers (wired to view callbacks) ──────────────────────────────

  void _handleFromLocationTap() async {
    _fromFocusNode.unfocus();
    await _updateLocationWithCurrentPosition(true, false);
    _fromController.text = 'Current Location';
  }

  void _handleToLocationTap() async {
    _toFocusNode.unfocus();
    await _updateLocationWithCurrentPosition(false, false);
    _toController.text = 'Current Location';
  }

  void _handleSwitch() {
    setState(() {
      _uiState.rotateSwitchButton = !_uiState.rotateSwitchButton;
    });
    String temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;

    var tempLocation = widget.page.from;
    widget.page.from = widget.page.to;
    widget.page.to = tempLocation;
  }

  void _handleStationSelected(Station station, bool searchingFrom) {
    setState(() {
      if (searchingFrom) {
        widget.page.from = station;
        _fromController.text = station.name;
        _fromFocusNode.unfocus();
      } else {
        widget.page.to = station;
        _toController.text = station.name;
        _toFocusNode.unfocus();
      }
    });
    _search();
  }

  void _handleLocationSelected(
      Location location, bool searchingFrom) {
    setState(() {
      if (searchingFrom) {
        widget.page.from = location;
        _fromController.text = location.name;
        _fromFocusNode.unfocus();
      } else {
        widget.page.to = location;
        _toController.text = location.name;
        _toFocusNode.unfocus();
      }
    });
    _search();
  }

  void _handleFaveChipTap(
      FavoriteLocation f, bool searchingFrom) {
    if (searchingFrom) {
      setState(() {
        _fromController.text = f.name;
        widget.page.from = f.location;
        _fromFocusNode.unfocus();
      });
    } else {
      setState(() {
        _toController.text = f.name;
        widget.page.to = f.location;
        _toFocusNode.unfocus();
      });
    }
    _search();
  }

  void _handleAddFavourite(Location location) async {
    List<FavoriteLocation> updatedFaves =
        await Localdatasaver.getFavouriteLocations();
    setState(() => _model.faves = updatedFaves);
  }

  void _handleRemoveFavourite(FavoriteLocation fave) {
    setState(() {
      _model.faves.remove(fave);
      Localdatasaver.removeFavouriteLocation(fave);
    });
  }

  void _handleJourneyTap(Journey j) async {
  RefreshJourneyPopUp.navigateToJourney(
    context,
    j,
    null, // no model needed here
    (_) async {}, // nothing to do after navigation on this page
  );
}

  void _handleResetToNow() {
    setState(() {
      _model.selectedTime = TimeOfDay.now();
      _model.selectedDate = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reset to current date and time'),
        duration: Duration(seconds: 2),
      ),
    );
    _search();
  }

  void _search() async {
  setState(() {
    _uiState.inJourneySearchAnimation = true;
    // ... rest unchanged
  });
    setState(() {
      _uiState.inJourneySearchAnimation = true;
      _uiState.rotatingSearchIconTurns++;
      _uiState.shouldAutoScrollToTop = true;
      _uiState.searching = false;
    });
    try {
      print('From: ${widget.page.from}');
      print('To: ${widget.page.to}');
      await _getJourneys();
    } catch (e) {
      print('Error in search: $e');
      setState(() {
        _model.currentJourneys = [];
        _uiState.inJourneySearchAnimation = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final view = ConnectionsPageView(
      model: _model,
      uiState: _uiState,
      fromController: _fromController,
      toController: _toController,
      fromFocusNode: _fromFocusNode,
      toFocusNode: _toFocusNode,
      scrollController: _scrollController,
      onFromLocationTap: _handleFromLocationTap,
      onToLocationTap: _handleToLocationTap,
      onSwitch: _handleSwitch,
      onStationSelected: _handleStationSelected,
      onLocationSelected: _handleLocationSelected,
      onSearch: _search,
      onAddEarlier: _addEarlierJourneys,
      onAddLater: _addLaterJourneys,
      onJourneyTap: _handleJourneyTap,
      onTimeChanged: (t) => setState(() => _model.selectedTime = t),
      onDateChanged: (d) => setState(() => _model.selectedDate = d),
      onDepartureChanged: (v) =>
          setState(() => _model.departure = v),
      onSettingsChanged: (s) =>
          setState(() => _model.journeySettings = s),
      onFaveChipTap: _handleFaveChipTap,
      onAddFavourite: _handleAddFavourite,
      onRemoveFavourite: _handleRemoveFavourite,
      onResetToNow: _handleResetToNow,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              view.buildInputFields(context),
              SizedBox(height: 16),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _uiState.searching
                    ? view.buildFaves(
                        context, _uiState.searchingFrom)
                    : view.buildButtons(context),
              ),
              if (_uiState.searching)
                Expanded(
                  child: view.buildSearchResults(
                      context, _uiState.searchingFrom),
                ),
              if (!_uiState.searching)
                view.buildJourneys(context),
            ],
          ),
        ),
      ),
    );
  }
}