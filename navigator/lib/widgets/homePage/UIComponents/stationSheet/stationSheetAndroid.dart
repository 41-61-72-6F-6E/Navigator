import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/models/station.dart';
import 'package:navigator/pages/android/connections_page_android.dart';
import 'package:navigator/pages/page_models/connections_page.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPage.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

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
    return Text("Station Sheet for ${station.name}"); // Placeholder content, replace with actual UI
  }
}

