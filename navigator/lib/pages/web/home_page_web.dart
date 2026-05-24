import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/home_page.dart';


class HomePageWeb extends HomePageIni
{
  HomePageWeb(this.page,{super.key});

  HomePageIni page;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Web Version'
    );
  }
}

