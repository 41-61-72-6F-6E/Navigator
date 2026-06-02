import 'package:flutter/material.dart';
import 'package:navigator/models/journeySettings.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';

class SearchButtonsAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final ConnectionsPageUIState uiState;
  final VoidCallback onSearch;
  final void Function(TimeOfDay) onTimeChanged;
  final void Function(DateTime) onDateChanged;
  final void Function(bool) onDepartureChanged;
  final void Function(JourneySettings) onSettingsChanged;

  const SearchButtonsAndroid({
    super.key,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.departure_board),
                label: Text(model.selectedTime.format(context)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: model.selectedTime,
                    helpText: 'Select Departure or Arrival Time',
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          timePickerTheme: TimePickerThemeData(
                            helpTextStyle: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) onTimeChanged(time);
                },
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.calendar_month),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: model.selectedDate,
                    helpText: 'Select Departure Or Arrival Date',
                  );
                  if (date != null) onDateChanged(date);
                },
                label: Text(
                  '${model.selectedDate.day}.${model.selectedDate.month}.${model.selectedDate.year}',
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _showSettingsDialog(context, colors),
              icon: Icon(Icons.settings),
              tooltip: 'Journey Settings',
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(value: true, label: Text('Departure')),
                  ButtonSegment<bool>(value: false, label: Text('Arrival')),
                ],
                selected: {model.departure},
                onSelectionChanged: (Set<bool> newSelection) =>
                    onDepartureChanged(newSelection.first),
              ),
            ),
            GestureDetector(
              onTap: onSearch,
              child: AnimatedContainer(
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      uiState.inJourneySearchAnimation ? 8 : 24),
                  color: uiState.inJourneySearchAnimation
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedRotation(
                        curve: Curves.easeInOut,
                        turns: uiState.rotatingSearchIconTurns,
                        duration: Duration(milliseconds: 600),
                        child: Icon(
                          Icons.search,
                          color: uiState.inJourneySearchAnimation
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Search',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(
                              color: uiState.inJourneySearchAnimation
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context, ColorScheme colors) async {
    JourneySettings tempSettings = JourneySettings(
      national: model.journeySettings.national,
      nationalExpress: model.journeySettings.nationalExpress,
      regional: model.journeySettings.regional,
      regionalExpress: model.journeySettings.regionalExpress,
      suburban: model.journeySettings.suburban,
      subway: model.journeySettings.subway,
      tram: model.journeySettings.tram,
      bus: model.journeySettings.bus,
      ferry: model.journeySettings.ferry,
      deutschlandTicketConnectionsOnly:
          model.journeySettings.deutschlandTicketConnectionsOnly,
      accessibility: model.journeySettings.accessibility,
      walkingSpeed: model.journeySettings.walkingSpeed,
      transferTime: model.journeySettings.transferTime,
    );

    final updatedSettings = await showDialog<JourneySettings>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Journey Preferences',
            style: TextStyle(color: colors.onSurface),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Modes of Transport',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      title: Text('Include ICE',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.national ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.national = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include IC/EC',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.nationalExpress ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.nationalExpress = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include RE/RB',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.regional ?? true,
                      onChanged: (value) => setState(() {
                        tempSettings.regional = value;
                        tempSettings.regionalExpress = value;
                      }),
                    ),
                    CheckboxListTile(
                      title: Text('Include S-Bahn',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.suburban ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.suburban = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include U-Bahn',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.subway ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.subway = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include Tram',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.tram ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.tram = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include Bus',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.bus ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.bus = value),
                    ),
                    CheckboxListTile(
                      title: Text('Include Ferry',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.ferry ?? true,
                      onChanged: (value) =>
                          setState(() => tempSettings.ferry = value),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Journey Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      title: Text('Deutschlandticket only',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.deutschlandTicketConnectionsOnly ??
                          false,
                      onChanged: (value) => setState(() =>
                          tempSettings.deutschlandTicketConnectionsOnly =
                              value),
                    ),
                    CheckboxListTile(
                      title: Text('Accessibility',
                          style: TextStyle(color: colors.onSurface)),
                      value: tempSettings.accessibility ?? false,
                      onChanged: (value) =>
                          setState(() => tempSettings.accessibility = value),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Walking Speed',
                              style: TextStyle(
                                  color: colors.onSurface, fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: tempSettings.walkingSpeed ?? 'normal',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                style: TextStyle(color: colors.onSurface),
                                iconEnabledColor: colors.primary,
                                items: [
                                  DropdownMenuItem(
                                      value: 'slow', child: Text('Slow')),
                                  DropdownMenuItem(
                                      value: 'normal', child: Text('Normal')),
                                  DropdownMenuItem(
                                      value: 'fast', child: Text('Fast')),
                                ],
                                onChanged: (value) => setState(
                                    () => tempSettings.walkingSpeed = value),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Transfer Time',
                              style: TextStyle(
                                  color: colors.onSurface, fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: tempSettings.transferTime,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                style: TextStyle(color: colors.onSurface),
                                iconEnabledColor: colors.primary,
                                items: [
                                  DropdownMenuItem(
                                      value: null,
                                      child: Text('Default (None)')),
                                  DropdownMenuItem(
                                      value: 5,
                                      child: Text('Min. 5 Minutes')),
                                  DropdownMenuItem(
                                      value: 15,
                                      child: Text('Min. 15 Minutes')),
                                  DropdownMenuItem(
                                      value: 30,
                                      child: Text('Min. 30 Minutes')),
                                ],
                                onChanged: (value) => setState(
                                    () => tempSettings.transferTime = value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(tempSettings),
              child: Text('Apply'),
            ),
          ],
        );
      },
    );

    if (updatedSettings != null) onSettingsChanged(updatedSettings);
  }
}