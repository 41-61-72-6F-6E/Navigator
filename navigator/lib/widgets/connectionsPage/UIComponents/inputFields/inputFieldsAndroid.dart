import 'package:flutter/material.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';

class InputFieldsAndroid extends StatelessWidget {
  final ConnectionsPageModel model;
  final ConnectionsPageUIState uiState;
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocusNode;
  final FocusNode toFocusNode;
  final VoidCallback onFromLocationTap;
  final VoidCallback onToLocationTap;
  final VoidCallback onSwitch;

  const InputFieldsAndroid({
    super.key,
    required this.model,
    required this.uiState,
    required this.fromController,
    required this.toController,
    required this.fromFocusNode,
    required this.toFocusNode,
    required this.onFromLocationTap,
    required this.onToLocationTap,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(width: 1, color: colors.outline),
        color: colors.secondaryContainer,
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: TextField(
                    controller: fromController,
                    focusNode: fromFocusNode,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      fillColor: colors.surface,
                      filled: true,
                      labelText: 'From',
                      labelStyle: TextStyle(color: colors.onSurface),
                      prefixIcon: GestureDetector(
                        onTap: onFromLocationTap,
                        child: Icon(Icons.location_on, color: colors.onSurface),
                      ),
                      border: OutlineInputBorder().copyWith(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: TextField(
                    controller: toController,
                    focusNode: toFocusNode,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      fillColor: colors.surface,
                      filled: true,
                      labelText: 'To',
                      labelStyle: TextStyle(color: colors.onSurface),
                      prefixIcon: GestureDetector(
                        onTap: onToLocationTap,
                        child: Icon(Icons.location_on, color: colors.onSurface),
                      ),
                      border: OutlineInputBorder().copyWith(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedRotation(
                  turns: uiState.rotateSwitchButton ? 0.5 : 0.0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.primary,
                      iconSize: 32,
                      side: BorderSide(color: colors.outline, width: 1),
                    ),
                    onPressed: onSwitch,
                    icon: Icon(Icons.swap_vert),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}