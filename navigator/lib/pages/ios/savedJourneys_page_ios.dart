import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';

class SavedjourneysPageIos extends SavedjourneysPage
{
  SavedjourneysPage page;
  SavedjourneysPageIos(this.page, {Key? key});

  
  @override
  Widget build(BuildContext context) {
    return Text(
      'Ios'
    );
  }
}