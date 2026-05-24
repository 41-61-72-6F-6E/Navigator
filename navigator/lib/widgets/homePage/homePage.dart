import 'package:flutter/material.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';
import 'package:navigator/widgets/homePage/homePageView.dart';

/// Main page widget for the Home page.
/// Creates the model and passes it to the view — mirrors the SavedJourneys pattern.
class HomePage extends StatefulWidget {
  final HomePageIni page;

  const HomePage(this.page, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomePageModel _model;

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
    return HomePageView(model: _model);
  }
}