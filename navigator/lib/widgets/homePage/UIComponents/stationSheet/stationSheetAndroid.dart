import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/GeneralUIComponents/sheetHandle/sheetHandle.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

typedef StationDepartureLoader =
    Future<List<DepartureArrival>> Function(Station station);

class StationSheetAndroid extends StatefulWidget {
  static const loadingKey = Key('station-board-loading');
  static const errorKey = Key('station-board-error');
  static const emptyKey = Key('station-board-empty');
  static const departuresKey = Key('station-board-departures');

  final HomePageModel model;
  final Station station;
  final StationDepartureLoader? departureLoader;

  const StationSheetAndroid({
    super.key,
    required this.model,
    required this.station,
    this.departureLoader,
  });

  @override
  State<StationSheetAndroid> createState() => _StationSheetAndroidState();
}

class _StationSheetAndroidState extends State<StationSheetAndroid> {
  late Future<List<DepartureArrival>> _departures;

  @override
  void initState() {
    super.initState();
    _departures = _loadDepartures();
  }

  Future<List<DepartureArrival>> _loadDepartures() async {
    final customLoader = widget.departureLoader;
    if (customLoader != null) {
      return customLoader(widget.station);
    }

    final selectedStation = await widget.model.selectStation(widget.station);
    if (selectedStation == null) {
      throw StateError(
        'The station could not be found by the departure service.',
      );
    }
    return widget.model.getDeparturesForStation(selectedStation);
  }

  Future<void> _refresh() async {
    final nextDepartures = _loadDepartures();
    setState(() {
      _departures = nextDepartures;
    });
    try {
      await nextDepartures;
    } catch (_) {
      // The FutureBuilder displays the retry state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: SheetHandle(design: 0)),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  widget.model.getTransportIcon(widget.station),
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.station.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stationKind(widget.station),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (_stationProducts(widget.station).isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                for (final product in _stationProducts(widget.station)) ...[
                  Chip(
                    avatar: Icon(product.icon, size: 18),
                    label: Text(product.label),
                    side: BorderSide.none,
                    backgroundColor: colors.secondaryContainer,
                    labelStyle: TextStyle(color: colors.onSecondaryContainer),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Next departures',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh departures',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DepartureArrival>>(
            future: _departures,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  key: StationSheetAndroid.loadingKey,
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return _MessageState(
                  key: StationSheetAndroid.errorKey,
                  icon: Icons.cloud_off,
                  title: 'Departures unavailable',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Try again',
                  onAction: _refresh,
                );
              }

              final departures = snapshot.data ?? const <DepartureArrival>[];
              if (departures.isEmpty) {
                return _MessageState(
                  key: StationSheetAndroid.emptyKey,
                  icon: Icons.departure_board,
                  title: 'No upcoming departures',
                  message: 'There are no departures in the next two hours.',
                  actionLabel: 'Refresh',
                  onAction: _refresh,
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  key: StationSheetAndroid.departuresKey,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: departures.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _DepartureCard(departure: departures[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final DepartureArrival departure;

  const _DepartureCard({required this.departure});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cancelled =
        departure.cancelled ||
        departure.remarks.any((remark) => remark.isCancellationRemark);
    final delayed =
        !cancelled &&
        (departure.delay ??
                departure.when.difference(departure.plannedWhen).inSeconds) >
            0;
    final platform = departure.platform ?? departure.plannedPlatform;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.Hm().format(departure.when.toLocal()),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cancelled
                          ? colors.error
                          : delayed
                          ? colors.tertiary
                          : colors.onSurface,
                      fontWeight: FontWeight.bold,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (delayed)
                    Text(
                      DateFormat.Hm().format(departure.plannedWhen.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 42, maxWidth: 78),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lineName(departure),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _departureDirection(departure),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (cancelled || delayed || platform != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (cancelled)
                          _StatusLabel(
                            icon: Icons.cancel_outlined,
                            text: 'Cancelled',
                            color: colors.error,
                          )
                        else if (delayed)
                          _StatusLabel(
                            icon: Icons.schedule,
                            text: _delayLabel(departure),
                            color: colors.tertiary,
                          ),
                        if (platform != null && platform.isNotEmpty)
                          _StatusLabel(
                            icon: Icons.signpost_outlined,
                            text: 'Platform $platform',
                            color: colors.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _StationProduct {
  final String label;
  final IconData icon;

  const _StationProduct(this.label, this.icon);
}

List<_StationProduct> _stationProducts(Station station) => [
  if (station.nationalExpress) const _StationProduct('High-speed', Icons.train),
  if (station.national) const _StationProduct('Intercity', Icons.train),
  if (station.regionalExpress)
    const _StationProduct('Regional express', Icons.directions_railway),
  if (station.regional)
    const _StationProduct('Regional', Icons.directions_transit),
  if (station.suburban)
    const _StationProduct('S-Bahn', Icons.directions_subway),
  if (station.subway) const _StationProduct('U-Bahn', Icons.subway),
  if (station.tram) const _StationProduct('Tram', Icons.tram),
  if (station.bus) const _StationProduct('Bus', Icons.directions_bus),
  if (station.ferry) const _StationProduct('Ferry', Icons.directions_ferry),
  if (station.taxi) const _StationProduct('Taxi', Icons.local_taxi),
];

String _stationKind(Station station) {
  if (station.nationalExpress || station.national) return 'Railway station';
  if (station.regionalExpress || station.regional || station.suburban) {
    return 'Train station';
  }
  if (station.subway) return 'Underground station';
  if (station.tram) return 'Tram stop';
  if (station.bus) return 'Bus stop';
  if (station.ferry) return 'Ferry terminal';
  return 'Transit stop';
}

String _lineName(DepartureArrival departure) {
  final name = departure.line?.name;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  final product = departure.line?.productName ?? departure.line?.product;
  if (product != null && product.trim().isNotEmpty) return product.trim();
  return '—';
}

String _departureDirection(DepartureArrival departure) {
  final direction = departure.direction?.trim();
  if (direction != null && direction.isNotEmpty) return direction;
  final destination = departure.destination?.name.trim();
  if (destination != null && destination.isNotEmpty) return destination;
  return 'Direction unavailable';
}

String _delayLabel(DepartureArrival departure) {
  final delaySeconds =
      departure.delay ??
      departure.when.difference(departure.plannedWhen).inSeconds;
  final minutes = (delaySeconds / Duration.secondsPerMinute).ceil();
  return '+$minutes min';
}
