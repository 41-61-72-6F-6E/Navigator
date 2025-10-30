import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUp.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/savedJourneyPageUIUtils.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';

class ListViewAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final Journey journey;

  const ListViewAndroid({
    super.key,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {    
    bool delayed = false;
    String timeText = SavedJourneyPageUIUtils.generateJourneyTimeText(journey, false, true);
    Text liveTimeTextP1 = const Text('');
    Text liveTimeTextP2 = const Text('');
    Icon modeIcon = Icon(
      Icons.train,
      color: Theme.of(context).colorScheme.tertiary,
    );

    String highestMode = SavedJourneyPageUIUtils.findHighestMode(journey);
    modeIcon = Icon(
      SavedJourneyPageUIUtils.getModeIcon(highestMode).icon,
      color: Theme.of(context).colorScheme.tertiary,
    );

    if (journey.legs.first.departureDelayMinutes != null ||
        journey.legs.last.arrivalDelayMinutes != null) {
      delayed = true;
    }

    Color y = Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 229, 241, 116)
        : const Color.fromARGB(255, 166, 175, 34);
    Color g = onSuccessColor;

    if (journey.legs.first.departureDelayMinutes != null) {
      delayed = true;
      Color c = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
      c = journey.legs.first.departureDelayMinutes! >= 15
          ? Theme.of(context).colorScheme.error
          : c;
      liveTimeTextP1 = Text(
        SavedJourneyPageUIUtils.generateLiveTimeText(journey, true, false),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
      );
    }

    if (journey.legs.last.arrivalDelayMinutes != null) {
      if (delayed) {
        Color cD = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
        cD = journey.legs.first.departureDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cD;
        Color cA = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        cA = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cA;
        liveTimeTextP1 = Text(
          SavedJourneyPageUIUtils.generateLiveTimeText(journey, true, false),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cD),
        );
        liveTimeTextP2 = Text(
          SavedJourneyPageUIUtils.generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cA),
        );
      } else {
        delayed = true;
        Color c = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        c = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : c;
        liveTimeTextP2 = Text(
          SavedJourneyPageUIUtils.generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
        );
        liveTimeTextP1 = Text(
          '        ',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: () => RefreshJourneyPopUp.navigateToJourney(context, journey, model, (model) async {
                await model.loadSavedJourneys();
                model.refreshJourneys(onlyFutureJourneys: !model.state.showingPastJourneys);
              }),
          leading: modeIcon,
          title: Text(
            '${journey.legs.first.origin.name} - ${journey.legs.last.destination.name}',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Row(
            children: [
              Text(
                timeText,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              if (delayed) liveTimeTextP1,
              if (delayed)
                Text(
                  ' - ',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              if (delayed) liveTimeTextP2,
            ],
          ),
          trailing: IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              "assets/Icon/transit_ticket.svg",
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onErrorContainer,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }

}