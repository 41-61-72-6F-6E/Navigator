import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
//import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/widgets/journeyPage/journeyPage.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/services/servicesMiddle.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUpAndroid.dart';

class RefreshJourneyPopUp {
  static final ServicesMiddle services = ServicesMiddle();
  static Future<void> navigateToJourney<T>(
    BuildContext context,
    Journey journey,
    T model,
    Future<void> Function(T model) onNavigationComplete,
  ) async {
    final outerContext = context;
    
    RefreshJourneyPopUpAndroid.show(
      outerContext,
      message: 'Refreshing journey information...',
    );

    try {
      final refreshedJourney = await services.refreshJourneyByToken(journey.refreshToken);
      
      RefreshJourneyPopUpAndroid.hide(outerContext);
      
      if (outerContext.mounted) {
        Navigator.of(outerContext, rootNavigator: false)
            .push(
          MaterialPageRoute(
            builder: (context) => JourneyPage(
              JourneyPageIni(journey: refreshedJourney),
              journey: refreshedJourney,
            ),
          ),
        )
            .then((_) async {
          await onNavigationComplete(model);
        });
      }
    } catch (e) {
      RefreshJourneyPopUpAndroid.hide(outerContext);
      
      if (outerContext.mounted) {
        ScaffoldMessenger.of(outerContext).showSnackBar(
          SnackBar(
            content: Text('Could not refresh journey: ${e.toString()}'),
            backgroundColor: Theme.of(outerContext).colorScheme.error,
          ),
        );
      }
    }
  }

 Future<Journey> refreshSingleJourney(String refreshToken) async {
    return await services.refreshJourneyByToken(refreshToken);
  }

}