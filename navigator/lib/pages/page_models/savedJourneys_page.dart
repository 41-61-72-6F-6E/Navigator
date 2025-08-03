import 'package:flutter/material.dart';
import 'package:navigator/pages/android/savedJourneys_page_android.dart';
import 'package:navigator/pages/linux/savedJourneys_page_linux.dart';
import 'package:navigator/pages/macos/savedJourneys_page_macos.dart';
import 'package:navigator/pages/web/savedJourneys_page_web.dart';
import 'package:navigator/pages/windows/savedJourneys_page_windows.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/services/servicesMiddle.dart';

class SavedjourneysPage extends StatelessWidget{
  List<String> savedJourneyrefreshTokens = [];

  final int design = 0; //0 = Android, 1 = ios, 2 = linux, 3 = macos, 4 = web, 5 = windows
  
  ServicesMiddle services = ServicesMiddle();


  Future<void> getSavedJourneyRefreshTokens() async {
    savedJourneyrefreshTokens = await Localdatasaver.getSavedJourneyRefreshTokens();
  }

  @override
  Widget build(BuildContext context) {
    switch(design)
    {
      case 1:
      return SavedjourneysPageAndroid(this);

      case 2:
      return SavedjourneysPageLinux(this);

      case 3:
      return SavedjourneysPageMacos(this);

      case 4:
      return SavedjourneysPageWeb(this);

      case 5:
      return SavedjourneysPageWindows(this);

      default:
      return SavedjourneysPageAndroid(this);
    }
    
  }
}