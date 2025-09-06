import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';

class SavedjourneysPageLinux extends SavedjourneysPage
{
  SavedjourneysPage page;
  SavedjourneysPageLinux(this.page, {super.key});

  
  @override
  Widget build(BuildContext context) {
    return Text(
      'Ios'
    );
  }
}