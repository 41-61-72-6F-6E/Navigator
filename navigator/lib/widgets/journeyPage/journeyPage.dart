import 'package:flutter/material.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/pages/page_models/journey_page.dart';
import 'package:navigator/widgets/journeyPage/journeyPageModel.dart';
import 'package:navigator/widgets/journeyPage/journeyPageView.dart';

/// Entry point for the Journey page on Android.
/// Creates the [JourneyPageAndroidModel] and hands it to [JourneyPageAndroidView].
class JourneyPageAndroid extends StatefulWidget {
  final JourneyPage page;
  final Journey journey;

  const JourneyPageAndroid(this.page, {super.key, required this.journey});

  @override
  State<JourneyPageAndroid> createState() => _JourneyPageAndroidState();
}

class _JourneyPageAndroidState extends State<JourneyPageAndroid> {
  late JourneyPageAndroidModel _model;

  @override
  void initState() {
    super.initState();
    _model = JourneyPageAndroidModel(
      page: widget.page,
      journey: widget.journey,
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JourneyPageAndroidView(model: _model);
  }
}