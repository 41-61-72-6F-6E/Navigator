import 'package:navigator/models/journey.dart';

class JourneyPageIni
{
  Journey journey;

  JourneyPageIni({required this.journey})
  {
    // Initialize line colors for all legs in the journey
    journey.initializeLineColors();
  }
}