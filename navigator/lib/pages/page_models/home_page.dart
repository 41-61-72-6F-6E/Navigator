import 'package:flutter/material.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/pages/android/home_page_android.dart';
import 'package:navigator/pages/ios/home_page_ios.dart';
import 'package:navigator/pages/linux/home_page_linux.dart';
import 'package:navigator/pages/macos/home_page_macos.dart';
import 'package:navigator/pages/web/home_page_web.dart';
import 'package:navigator/pages/windows/home_page_windows.dart';
import 'package:navigator/services/servicesMiddle.dart';

class HomePage extends StatelessWidget
{
  HomePage({super.key});

  //search Button
  bool ongoingJourney = false;
  ServicesMiddle service = new ServicesMiddle();

  final int design = 0; //0 = Android, 1 = ios, 2 = linux, 3 = macos, 4 = web, 5 = windows
  
  Future<List<Location>> getLocations(String query) async
  {
    return await service.getLocations(query);
  }



  //bottom Bar home and saved
  //map
  @override
  Widget build(BuildContext context) {
    switch(design)
    {
      case 1:
      return HomePageIos(this );

      case 2:
      return HomePageLinux(this );

      case 3:
      return HomePageMacos(this );

      case 4:
      return HomePageWeb(this );

      case 5:
      return HomePageWindows(this);

      default:
      return HomePageAndroid(this );
    }
    
  }
}