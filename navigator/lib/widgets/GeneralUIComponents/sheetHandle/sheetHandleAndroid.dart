import 'package:flutter/material.dart';


class SheetHandleAndroid extends StatelessWidget {

  const SheetHandleAndroid({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Container(
        height: 4,
        width: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}