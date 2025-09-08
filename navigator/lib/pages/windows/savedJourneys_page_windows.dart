import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/savedJourneys_page.dart';
import 'package:navigator/services/servicesMiddle.dart';

class SavedjourneysPageWindows extends SavedjourneysPage
{
  SavedjourneysPage page;
  SavedjourneysPageWindows(this.page, {super.key});
  final ServicesMiddle _servicesMiddle = ServicesMiddle();

  
  @override
  Widget build(BuildContext context) {
    return Text(
      'Ios'
    );
  }
}