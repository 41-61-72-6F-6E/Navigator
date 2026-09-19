import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/widgets/GeneralUIComponents/generalUiUtilities.dart';
import 'package:navigator/widgets/GeneralUIComponents/lineChip/lineChip.dart';

class DepartureChipAndroid extends StatelessWidget {
  final DateTime newTime;
  final DateTime? origTime;
  final String? newPlatform;
  final String? origPlatform;

  const DepartureChipAndroid({
    super.key,
    required this.newTime,
    this.origTime,
    required this.newPlatform,
    this.origPlatform,
  });

  @override
  Widget build(BuildContext context) {
    if (origTime == null || (origTime == newTime && (origPlatform == null || origPlatform == newPlatform))) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
          child: Column(
            children: [
              Text(GeneralUIUtilities().getTextfromDateTime(newTime), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
              if (newPlatform != null) Text("Pl. $newPlatform", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
            ],
          ),
        ),
      );
    } else {
      return Container(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                child: Column(
                  children: [
                    Text(GeneralUIUtilities().getTextfromDateTime(origTime!), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onError, decoration: TextDecoration.lineThrough, decorationColor: Theme.of(context).colorScheme.onError)),
                    if (origPlatform != null) Text("Pl. $origPlatform", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onError, decoration: TextDecoration.lineThrough, decorationColor: Theme.of(context).colorScheme.onError)),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Column(
                  children: [
                    Text(GeneralUIUtilities().getTextfromDateTime(newTime), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                    if (newPlatform != null) Text("Pl. $newPlatform", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
