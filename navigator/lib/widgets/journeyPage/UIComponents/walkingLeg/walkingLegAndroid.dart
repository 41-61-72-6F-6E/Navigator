import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:navigator/models/leg.dart';

class WalkingLegAndroid extends StatelessWidget {
  final Leg leg;
  final VoidCallback onMapPressed;

  const WalkingLegAndroid({
    super.key,
    required this.leg,
    required this.onMapPressed,
  });

  String _formatLegDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '0min';
    final duration = end.difference(start);
    final minutes = (duration.inSeconds / 60).ceil();
    return minutes <= 0 ? '1min' : '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    if (leg.distance == null || leg.distance == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(width: (constraints.maxWidth / 100) * 12),
                      const Icon(Icons.directions_walk),
                      const SizedBox(width: 8),
                      Text(
                        'Walk ${leg.distance}m (${_formatLegDuration(leg.departureDateTime, leg.arrivalDateTime)})',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const Spacer(),
                      IconButton.filled(
                        onPressed: onMapPressed,
                        icon: const Icon(Icons.map),
                        color: Theme.of(context).colorScheme.tertiary,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.tertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                right: constraints.maxWidth / 100 * 88,
                left: constraints.maxWidth / 100 * 6,
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                      radius: const Radius.circular(24)),
                  child: Container(
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}