import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/mapOptionsModal/mapOptionsModalAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class MapOptionsModal {
  static void show(BuildContext context, HomePageModel model, {int design = 0}) {
    switch (design) {
      case 0:
        MapOptionsModalAndroid.show(context, model);
        break;
      // Future designs can be added here
      default:
        MapOptionsModalAndroid.show(context, model);
    }
  }
}