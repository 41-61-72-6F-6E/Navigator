import 'package:flutter/material.dart';
import 'package:navigator/pages/android/journey_page_android.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/services/localDataSaver.dart';

class SavedjourneysPageAndroid extends StatefulWidget {
  final SavedjourneysPage page;

  SavedjourneysPageAndroid(this.page, {Key? key}) : super(key: key);

  @override
  State<SavedjourneysPageAndroid> createState() => _SavedjourneysPageAndroidState();

  

}

class _SavedjourneysPageAndroidState extends State<SavedjourneysPageAndroid>{

  List<String> savedJourneyrefreshTokens = [];

  @override
  void initState() {
    super.initState();
      getSavedJourneyRefreshTokens();
    }

  Future<void> getSavedJourneyRefreshTokens() async {
    List<String> s = await Localdatasaver.getSavedJourneyRefreshTokens();
    setState(() {
      savedJourneyrefreshTokens = s;
      print('Saved journey refresh tokens loaded: ${widget.page.savedJourneyrefreshTokens}');
    });
  }

  @override
  void dispose() {  
    super.dispose();
  }


    @override
    Widget build(BuildContext context)
    {
      return Scaffold(
        body: SafeArea(child: 
        Scaffold(
          body: _buildBody(context),
        )),
        
        );
    }

  Widget _buildBody(BuildContext context) {
    return ListView.builder(
      itemCount: savedJourneyrefreshTokens.length,
      itemBuilder: (context, index) {
        final journey = savedJourneyrefreshTokens[index];
        return ListTile(
          title: Text(journey),
          onTap: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Refreshing journey information...',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                );

                try {
                  // Refresh the journey using the service
                  final refreshedJourney = await widget.page.services.refreshJourneyByToken(journey);

                  // Close the loading dialog
                  Navigator.pop(context);

                  // Navigate to journey page with the refreshed journey
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JourneyPageAndroid(
                        JourneyPage(journey: refreshedJourney),
                        journey: refreshedJourney,
                      ),
                    ),
                  );
                } catch (e) {
                  // Close the loading dialog
                  Navigator.pop(context);

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not refresh journey: ${e.toString()}',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );

                  // Navigate with the original journey as fallback
                }
              },
        );
      },
    );

    
  }

}