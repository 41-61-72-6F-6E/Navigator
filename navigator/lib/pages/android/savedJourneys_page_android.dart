import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';

class SavedjourneysPageAndroid extends StatefulWidget {
  final SavedjourneysPage page;

  SavedjourneysPageAndroid(this.page, {Key? key}) : super(key: key);

  @override
  State<SavedjourneysPageAndroid> createState() => _SavedjourneysPageAndroidState();

  

}

class _SavedjourneysPageAndroidState extends State<SavedjourneysPageAndroid>{
  @override
  void initState() {
    super.initState();
    
    }

  @override
  void dispose() {  
    super.dispose();
  }


    @override
    Widget build(BuildContext context)
    {
      return Scaffold(
        body: Text('Saved Journeys'),
        
        );
    }

    
  }

