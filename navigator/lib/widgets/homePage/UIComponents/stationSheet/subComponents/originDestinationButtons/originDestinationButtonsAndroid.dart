import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';

class originDestinationButtonsAndroid extends StatelessWidget {
  final VoidCallback onOriginPressed;
  final VoidCallback onDestinationPressed;

  const originDestinationButtonsAndroid({
    super.key,
    required this.onOriginPressed,
    required this.onDestinationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(width: 16),
        Expanded(
          child: M3EFilledButton.tonal(
            shape: M3EButtonShape.square,
            size: M3EButtonSize.sm,
            semanticLabel: "Set as Origin",
            onPressed: onOriginPressed,
            child: Text("Use as Origin"),
          ),
        ),
        SizedBox(width: 8,),
        Expanded(
          child: M3EFilledButton.tonal(
            shape: M3EButtonShape.square,
            size: M3EButtonSize.sm,
            onPressed: onDestinationPressed,
            child: Text("Use as Destination"),
          ),
        ),
        SizedBox(width: 16,)
      ],
    );
  }
}