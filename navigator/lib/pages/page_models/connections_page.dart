import 'package:navigator/models/location.dart';
import 'package:navigator/services/servicesMiddle.dart';

class ConnectionsPageIni 
{
  Location to;
  Location from;
  ServicesMiddle services;

  ConnectionsPageIni({required this.from,required this.to, required this.services});
}