import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/editFavoritesModal/editFavoritesModalAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class EditFavoritesModal {
  static void show(BuildContext context, HomePageModel model, {int design = 0}) {
    switch (design) {
      case 0:
        EditFavoritesModalAndroid.show(context, model);
        break;
      // Future designs can be added here
      default:
        EditFavoritesModalAndroid.show(context, model);
    }
  }
}