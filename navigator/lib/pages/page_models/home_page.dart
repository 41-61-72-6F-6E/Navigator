import 'package:flutter/material.dart';
import 'package:navigator/models/location.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/homePage/homePage.dart';

class HomePageIni extends StatelessWidget
{
  HomePageIni({super.key});

  //search Button
  bool ongoingJourney = false;
  ServicesMiddle service = ServicesMiddle();

  final int design = 0; //0 = Android, 1 = ios, 2 = linux, 3 = macos, 4 = web, 5 = windows
  
  Future<List<Location>> getLocations(String query) async
  {
    return await service.getLocations(query);
  }



  //bottom Bar home and saved
  //map
  @override
  Widget build(BuildContext context) {
    return HomePage(  this);
  }
}