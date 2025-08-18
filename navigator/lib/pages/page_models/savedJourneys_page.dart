import 'package:flutter/material.dart';
import 'package:navigator/pages/android/savedJourneys_page_android.dart';
import 'package:navigator/pages/linux/savedJourneys_page_linux.dart';
import 'package:navigator/pages/macos/savedJourneys_page_macos.dart';
import 'package:navigator/pages/web/savedJourneys_page_web.dart';
import 'package:navigator/pages/windows/savedJourneys_page_windows.dart';
import 'package:navigator/services/localDataSaver.dart';
import 'package:navigator/services/servicesMiddle.dart';

class SavedjourneysPage extends StatefulWidget {
  int design;
  SavedjourneysPage({Key? key, this.design = 0}) : super(key: key);
  ServicesMiddle services = ServicesMiddle();

  @override
  SavedjourneysPageState createState() => SavedjourneysPageState();
}

class SavedjourneysPageState extends State<SavedjourneysPage> {
List<String> savedJourneyrefreshTokensState = [];

  @override
  void initState() {
    super.initState();
    getSavedJourneyRefreshTokens();
  }

  Future<void> getSavedJourneyRefreshTokens() async {
    savedJourneyrefreshTokensState = await Localdatasaver.getSavedJourneyRefreshTokens();
    setState(() {}); 
  }

  void reloadPage() {
    print('reloaded');
    getSavedJourneyRefreshTokens();
  }

  @override
  Widget build(BuildContext context) {
    switch(widget.design) {
      case 1: return SavedjourneysPageAndroid(widget, savedJourneyrefreshTokensState);
      case 2: return SavedjourneysPageLinux(widget);
      case 3: return SavedjourneysPageMacos(widget);
      case 4: return SavedjourneysPageWeb(widget);
      case 5: return SavedjourneysPageWindows(widget);
      default: return SavedjourneysPageAndroid(widget, savedJourneyrefreshTokensState);
    }
  }
}
