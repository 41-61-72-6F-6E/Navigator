import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/modeLine/modeLineAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class ModeLine extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final Journey journey;

  const ModeLine({
    super.key,
    required this.design,
    required this.model,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return ModeLineAndroid(model: model, journey: journey);
      default:
        return ModeLineAndroid(model: model, journey: journey);
    }
  }
}