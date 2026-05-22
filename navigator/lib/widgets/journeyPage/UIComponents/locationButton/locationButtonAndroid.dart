import 'package:flutter/material.dart';

class LocationButtonAndroid extends StatelessWidget {
  final VoidCallback onPressed;

  const LocationButtonAndroid({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20.0,
      bottom: 116.0,
      child: Material(
        elevation: 4.0,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 56.0,
            height: 56.0,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.my_location,
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}