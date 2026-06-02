import 'package:flutter/material.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/inputFields/inputFieldsAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageUIState.dart';

class InputFields extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final ConnectionsPageUIState uiState;
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocusNode;
  final FocusNode toFocusNode;
  final VoidCallback onFromLocationTap;
  final VoidCallback onToLocationTap;
  final VoidCallback onSwitch;

  const InputFields({
    super.key,
    required this.design,
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
    switch (design) {
      case 0:
        return InputFieldsAndroid(
          model: model,
          uiState: uiState,
          fromController: fromController,
          toController: toController,
          fromFocusNode: fromFocusNode,
          toFocusNode: toFocusNode,
          onFromLocationTap: onFromLocationTap,
          onToLocationTap: onToLocationTap,
          onSwitch: onSwitch,
        );
      default:
        return InputFieldsAndroid(
          model: model,
          uiState: uiState,
          fromController: fromController,
          toController: toController,
          fromFocusNode: fromFocusNode,
          toFocusNode: toFocusNode,
          onFromLocationTap: onFromLocationTap,
          onToLocationTap: onToLocationTap,
          onSwitch: onSwitch,
        );
    }
  }
}