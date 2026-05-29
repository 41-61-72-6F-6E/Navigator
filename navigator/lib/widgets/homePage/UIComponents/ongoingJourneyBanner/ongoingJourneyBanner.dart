import 'package:flutter/material.dart';
import 'package:navigator/widgets/homePage/UIComponents/ongoingJourneyBanner/ongoingJourneyBannerAndroid.dart';
import 'package:navigator/widgets/homePage/homePageModel.dart';

class OngoingJourneyBanner extends StatelessWidget {
  final int design;
  final HomePageModel model;

  const OngoingJourneyBanner({
    super.key,
    required this.design,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return OngoingJourneyBannerAndroid(model: model);
      // Future designs can be added here
      default:
        return OngoingJourneyBannerAndroid(model: model);
    }
  }
}