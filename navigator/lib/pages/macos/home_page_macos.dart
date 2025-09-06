import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/home_page.dart';


class HomePageMacos extends HomePage
{
  HomePageMacos(this.page,{super.key});

  HomePage page;

  @override
  Widget build(BuildContext context) {
    return Text(
      'MacOs'
    );
  }
}

