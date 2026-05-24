import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/home_page.dart';


class HomePageWindows extends HomePageIni
{
  HomePageWindows(this.page, {super.key});

  HomePageIni page;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Windows'
    );
  }
}

