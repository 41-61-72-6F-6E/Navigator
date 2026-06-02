import 'package:flutter/material.dart';
import 'package:navigator/models/favouriteLocation.dart';
import 'package:navigator/widgets/connectionsPage/UIComponents/favesRow/favesRowAndroid.dart';
import 'package:navigator/widgets/connectionsPage/connectionsPageModel.dart';

class FavesRow extends StatelessWidget {
  final int design;
  final ConnectionsPageModel model;
  final bool searchingFrom;
  final void Function(FavoriteLocation, bool searchingFrom) onFaveChipTap;

  const FavesRow({
    super.key,
    required this.design,
    required this.model,
    required this.searchingFrom,
    required this.onFaveChipTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case 0:
        return FavesRowAndroid(
          model: model,
          searchingFrom: searchingFrom,
          onFaveChipTap: onFaveChipTap,
        );
      default:
        return FavesRowAndroid(
          model: model,
          searchingFrom: searchingFrom,
          onFaveChipTap: onFaveChipTap,
        );
    }
  }
}