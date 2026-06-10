import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:navigator/models/leg.dart';
import 'package:navigator/models/remark.dart';
import 'package:navigator/models/stopover.dart';
import 'package:navigator/widgets/GeneralUIComponents/lineChip/lineChip.dart';

class LegWidget extends StatefulWidget {
  final Leg leg;
  Color colorArg;
  final VoidCallback? onMapPressed;

  LegWidget({
    super.key,
    required this.leg,
    required this.colorArg,
    this.onMapPressed,
  });

  @override
  State<LegWidget> createState() => _LegWidgetState();
}

class _LegWidgetState extends State<LegWidget> {
  bool _isExpanded = false;
  Remark? comfortCheckinRemark;
  Remark? bicycleRemark;
  Remark? infoRemark;
  late VoidCallback _colorListener;
  Color lineColor = Colors.grey;
  Color onLineColor = Colors.black;

  @override
  void initState() {
    super.initState();
    lineColor = widget.colorArg;
    try {
      comfortCheckinRemark = widget.leg.remarks!
          .firstWhere((r) => r.summary == 'Komfort-Checkin available');
    } catch (_) {
      comfortCheckinRemark = null;
    }
    try {
      bicycleRemark = widget.leg.remarks!
          .firstWhere((r) => r.summary == 'bicycles conveyed');
    } catch (_) {
      bicycleRemark = null;
    }
    try {
      infoRemark =
          widget.leg.remarks!.firstWhere((r) => r.type == 'status');
    } catch (_) {
      infoRemark = null;
    }

    final brightness = ThemeData.estimateBrightnessForColor(lineColor);
    onLineColor =
        brightness == Brightness.light ? Colors.black : Colors.white;

    _colorListener = () {
      if (mounted) {
        setState(() {
          lineColor = widget.leg.lineColorNotifier.value ?? Colors.grey;
          final b = ThemeData.estimateBrightnessForColor(lineColor);
          onLineColor =
              b == Brightness.light ? Colors.black : Colors.white;
        });
      }
    };
    widget.leg.lineColorNotifier.addListener(_colorListener);
  }

  @override
  void dispose() {
    widget.leg.lineColorNotifier.removeListener(_colorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intermediateStops = widget.leg.stopovers.length > 2
        ? widget.leg.stopovers.sublist(1, widget.leg.stopovers.length - 1)
        : <Stopover>[];
    final stopOrStops = intermediateStops.length == 1 ? 'stop' : 'stops';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final hasIntermediateStops = widget.leg.stopovers.length > 2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: lineColor.withAlpha(100),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                              width: (constraints.maxWidth / 100) * 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.leg.lineName != null &&
                                    widget.leg.lineName!.isNotEmpty)
                                  Row(
                                    children: [
                                      LineChip(
                                        design: 0,
                                        lineName: widget.leg.lineName!,
                                        lineColor: lineColor,
                                        onLineColor: onLineColor,
                                      ),
                                      if (widget.leg.direction != null &&
                                          widget.leg.direction!.isNotEmpty)
                                        const SizedBox(width: 8),
                                      if (widget.leg.direction != null &&
                                          widget.leg.direction!.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            widget.leg.direction!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                                    color: onLineColor),
                                            overflow:
                                                TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.start,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    if (comfortCheckinRemark != null)
                                      remark(context, comfortCheckinRemark!),
                                    if (bicycleRemark != null)
                                      remark(context, bicycleRemark!),
                                  ],
                                ),
                                if (infoRemark != null)
                                  info(context, infoRemark!),
                                if (!hasIntermediateStops)
                                  FilledButton.tonal(
                                    onPressed: () {},
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStateProperty.all(
                                        ThemeData.estimateBrightnessForColor(
                                                    lineColor) ==
                                                Brightness.dark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                      ),
                                      foregroundColor:
                                          WidgetStateProperty.all(
                                        ThemeData.estimateBrightnessForColor(
                                                    lineColor) ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                    child: const Text('No intermediate stops'),
                                  ),
                                if (hasIntermediateStops)
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    label: Text(_isExpanded
                                        ? 'Hide ${intermediateStops.length} $stopOrStops'
                                        : 'Show ${intermediateStops.length} $stopOrStops'),
                                    icon: AnimatedRotation(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      turns: _isExpanded ? .5 : 0,
                                      child: const Icon(
                                          Icons.arrow_drop_down),
                                    ),
                                    iconAlignment: IconAlignment.end,
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStateProperty.all(
                                              lineColor.withAlpha(120)),
                                      foregroundColor:
                                          WidgetStateProperty.all(
                                              onLineColor),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 80),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildStopsList(context),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                right: constraints.maxWidth / 100 * 88,
                left: constraints.maxWidth / 100 * 6,
                child: Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 16,
                child: IconButton.filled(
                  onPressed: widget.onMapPressed,
                  icon: const Icon(Icons.map),
                  color: Theme.of(context).colorScheme.tertiary,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopsList(BuildContext context) {
    final intermediateStops = widget.leg.stopovers.length > 2
        ? widget.leg.stopovers.sublist(1, widget.leg.stopovers.length - 1)
        : <Stopover>[];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              (constraints.maxWidth / 100) * 12 + 16, 0, 16 + 80, 16),
          child: Container(
            decoration: BoxDecoration(
              color: lineColor.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: lineColor.withAlpha(100), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: intermediateStops.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: lineColor.withAlpha(100)),
                  itemBuilder: (context, index) =>
                      _buildStopItem(context, intermediateStops[index]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStopItem(BuildContext context, Stopover stopover) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stopover.station.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onLineColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (stopover.effectiveArrivalDateTimeLocal != null)
                Text(
                  'Arr: ${_formatTime(stopover.effectiveArrivalDateTimeLocal!)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onLineColor),
                ),
              if (stopover.effectiveDepartureDateTimeLocal != null)
                Text(
                  'Dep: ${_formatTime(stopover.effectiveDepartureDateTimeLocal!)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onLineColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatModifiedDate(String? modifiedStr) {
    if (modifiedStr == null || modifiedStr.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(modifiedStr);
      if (dateTime.isUtc) dateTime = dateTime.toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    } catch (_) {
      return modifiedStr;
    }
  }

  void _showInformationPopup(BuildContext context, Remark remark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remark.summary ?? 'Information',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
              if (remark.modified != null) const SizedBox(height: 4),
              Text(
                'Last updated: ${_formatModifiedDate(remark.modified)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (remark.text != null && remark.text!.isNotEmpty)
                Text(
                  remark.text!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showRemarkPopup(BuildContext context, Remark remark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              _getRemarkIcon(remark.summary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remark.summary ?? 'Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (remark.text != null && remark.text!.isNotEmpty)
                Text(
                  remark.text!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _getRemarkIcon(String? summary) {
    switch (summary) {
      case 'Komfort-Checkin available':
        return Icon(Icons.check_circle_outline,
            size: 20, color: Theme.of(context).colorScheme.primary);
      case 'bicycles conveyed':
        return Icon(Icons.pedal_bike_outlined,
            size: 20, color: Theme.of(context).colorScheme.secondary);
      default:
        return Icon(Icons.info_outline,
            size: 20, color: Theme.of(context).colorScheme.tertiary);
    }
  }

  Widget info(BuildContext context, Remark remark) {
    return FilledButton.tonalIcon(
      onPressed: () => _showInformationPopup(context, remark),
      label: const Text('Further Information'),
      icon: const Icon(Icons.chevron_right),
      iconAlignment: IconAlignment.end,
      style: ButtonStyle(
        backgroundColor:
            WidgetStateProperty.all(lineColor.withAlpha(120)),
        foregroundColor: WidgetStateProperty.all(onLineColor),
      ),
    );
  }

  Widget remark(BuildContext context, Remark remark) {
    Icon icon = const Icon(Icons.power_off);
    switch (remark.summary) {
      case 'Komfort-Checkin available':
        icon = const Icon(Icons.check_circle_outline, size: 12);
        break;
      case 'bicycles conveyed':
        icon = const Icon(Icons.pedal_bike_outlined, size: 12);
        break;
    }

    if (remark.summary == null || remark.summary!.isEmpty) {
      return const SizedBox.shrink();
    }

    return IntrinsicWidth(
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () => _showRemarkPopup(context, remark),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    remark.summary!,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: onLineColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}