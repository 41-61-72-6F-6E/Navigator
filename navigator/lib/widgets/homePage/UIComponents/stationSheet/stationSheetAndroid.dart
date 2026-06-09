import 'package:flutter/material.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/GeneralUIComponents/sheetHandle/sheetHandle.dart';

class StationSheetAndroid extends StatelessWidget {
  final HomePageModel model;
  final Station station;

  const StationSheetAndroid({
    super.key,
    required this.model,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: SheetHandle(design: 0)),
        Text("Station Sheet for ${station.name}"),
      ],
    ); // Placeholder content, replace with actual UI
  }
}

