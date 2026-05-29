import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/homePage/homePageView.dart';

class HomePage extends StatefulWidget {
  final HomePageIni page;

  const HomePage(this.page, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomePageModel _model;
  final int design = 0;

  @override
  void initState() {
    super.initState();
    _model = HomePageModel(page: widget.page);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePageView(model: _model, design: design);
  }
}